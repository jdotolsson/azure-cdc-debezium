using Newtonsoft.Json.Linq;
using System.Collections;

namespace ChangeFeed.Processor.Parser
{
   public class Fields : IEnumerable<Field>
   {
      private readonly JObject _body;
      private readonly string SectionName;
      private JObject Schema => _body.GetOrThrow("schema");
      private JObject Section => _body.GetOrThrow("payload").GetOrThrow(SectionName);
      private readonly Dictionary<string, string> _fields = [];

      public object this[string fieldName]
      {
         get
         {
            return GetValue(fieldName);
         }
      }

      public IEnumerator<Field> GetEnumerator()
      {
         foreach (var f in _fields)
         {
            yield return new Field(f.Key, this[f.Key]);
         }
      }

      IEnumerator IEnumerable.GetEnumerator()
      {
         return GetEnumerator();
      }

      public Fields(JObject body, string sectionName)
      {
         _body = body;
         SectionName = sectionName;

         var fields = (JArray)Schema["fields"][0]["fields"];

         foreach (var f in fields.ToArray())
         {
            string name = f["field"].ToString();
            string type = f["type"].ToString();
            string debeziumType = f["name"]?.ToString();
            _fields.Add(name, debeziumType ?? "");
         }
      }

      public object GetValue(string fieldName)
      {
         var property = Section.Property(fieldName);

         string result = property.Value.ToString();
         string debeziumType = _fields[property.Name];

         if (string.IsNullOrEmpty(result))
            return result;

         if (string.IsNullOrEmpty(_fields[property.Name])) // not a debezium data type
            return result;

         switch (_fields[property.Name])
         {
            case "io.debezium.time.Date":
               var daysFromEoch = int.Parse(result);
               return Utils.Epoch.AddDays(daysFromEoch).Date;

            case "io.debezium.time.Time":
               var millisecondFromMidnight = int.Parse(result);
               return Utils.Epoch.AddMilliseconds(millisecondFromMidnight).TimeOfDay;

            case "io.debezium.time.MicroTime":
               var elapsedMicroSeconds = long.Parse(result);
               return Utils.Epoch.AddTicks(elapsedMicroSeconds * 10).TimeOfDay;

            case "io.debezium.time.NanoTime":
               var elapsedNanoSeconds = long.Parse(result);
               return Utils.Epoch.AddTicks(elapsedNanoSeconds / 100).TimeOfDay;

            case "io.debezium.time.Timestamp":
               var elapsedMilliseconds = long.Parse(result);
               return Utils.Epoch.AddMilliseconds(elapsedMilliseconds);

            case "io.debezium.time.MicroTimestamp":
               var elapsedMicroSeconds2 = long.Parse(result);
               return Utils.Epoch.AddMilliseconds(elapsedMicroSeconds2 * 10);

            case "io.debezium.time.NanoTimestamp":
               var elapsedNanoSeconds2 = long.Parse(result);
               return Utils.Epoch.AddTicks(elapsedNanoSeconds2 / 100);

            default:
               throw new ApplicationException($"'{debeziumType}' is unknown");
         }
      }
   }
}
