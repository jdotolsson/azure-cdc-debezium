namespace ChangeFeed.Processor.Parser
{
   public class DatabaseInfo
   {
      public string Database { get; }     

      public DatabaseInfo(string database)
      {
         Database = database;
      }
   }
}
