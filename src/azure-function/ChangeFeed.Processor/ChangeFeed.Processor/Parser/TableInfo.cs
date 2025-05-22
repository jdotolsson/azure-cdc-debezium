namespace ChangeFeed.Processor.Parser
{
   public class TableInfo
   {
      public string Schema { get; }
      public string Table { get; }
      public DateTime ChangedAt { get; }

      public TableInfo(string schema, string table, DateTime timeStamp)
      {
         Schema = schema;
         Table = table;
         ChangedAt = timeStamp;
      }
   }
}
