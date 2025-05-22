using Newtonsoft.Json.Linq;

namespace ChangeFeed.Processor.Parser
{
   public class ChangeFeedParser
   {
      private readonly JObject _body;
      private readonly JObject _payload;
      private readonly JObject _source;
      public TableInfo TableInfo { get; }
      public DatabaseInfo DatabaseInfo { get; }
      public Fields After { get; }
      public Fields Before { get; }
      public Operation Operation { get; }
      public ChangeType Type { get; } = ChangeType.Table;

      public ChangeFeedParser(JObject body)
      {
         _body = body;

         _payload = _body.GetOrThrow("payload");
         _source = _payload.GetOrThrow("source");

         TableInfo = new TableInfo(
             schema: _source.GetStringOrDefault("schema"),
             table: _source.GetStringOrDefault("table"),
             timeStamp: Utils.Epoch.AddMilliseconds(long.Parse(_source.GetStringOrDefault("ts_ms")))
         );

         DatabaseInfo = new DatabaseInfo(
             database: _source.GetStringOrDefault("db")
         );

         Before = new Fields(body, "before");
         After = new Fields(body, "after");

         Operation = GetOperation();
      }

      public ChangeType GetChangeFeedType()
      {
         return _body.ContainsKey("tablechanges") ? ChangeType.Schema : ChangeType.Table;
      }

      private Operation GetOperation()
      {
         var op = _payload["op"]?.ToString();
         return op switch
         {
            "c" => Operation.Insert,
            "u" => Operation.Update,
            "d" => Operation.Delete,
            _ => throw new ApplicationException("Field 'op' contains an unknown value or doesn't exist.")
         };
      }
   }
}
