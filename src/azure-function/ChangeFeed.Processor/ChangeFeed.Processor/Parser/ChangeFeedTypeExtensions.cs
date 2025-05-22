using Newtonsoft.Json.Linq;

namespace ChangeFeed.Processor.Parser
{
   public static class ChangeFeedTypeExtensions
   {
      public static ChangeType GetChangeFeedType(this JObject body)
      {
         return body.ContainsKey("tablechanges") ? ChangeType.Schema : ChangeType.Table;
      }

      public static JObject GetOrThrow(this JObject obj, string key)
      {
         if (obj.TryGetValue(key, out JToken? value) && value is JObject jObject)
         {
            return jObject;
         }
         throw new ApplicationException($"Field '{key}' doesn't exist.");
      }

      public static string GetStringOrDefault(this JObject obj, string key, string defaultValue = "")
      {
         if (obj.TryGetValue(key, out JToken? value))
         {
            return value?.ToString() ?? defaultValue;
         }
         throw new ApplicationException($"Field '{key}' doesn't exist.");
      }
   }
}
