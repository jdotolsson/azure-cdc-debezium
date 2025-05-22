namespace ChangeFeed.Processor.Settings
{
   public class AppSettings
   {
      public IReadOnlyList<ChangeFeedTarget> ChangeFeedTargets { get; set; } = [];
   }

   public class ChangeFeedTarget
   {
      public ChangeFeedSource Source { get; set; } = new ChangeFeedSource();
      public ChangeFeedDestination Destination { get; set; } = new ChangeFeedDestination();
      public IReadOnlyList<string> Triggers { get; set; } = [];
   }

   public class ChangeFeedSource
   {
      public string Database { get; set; } = string.Empty;
      public string Schema { get; set; } = string.Empty;
      public string TableName { get; set; } = string.Empty;
   }

   public class ChangeFeedDestination
   {
      public string RouteDatacontract { get; set; } = string.Empty;
      public string AzureQueueName { get; set; } = string.Empty;
   }
}
