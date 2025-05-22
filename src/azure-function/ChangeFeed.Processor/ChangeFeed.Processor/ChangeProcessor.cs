using Azure.Storage.Queues;
using ChangeFeed.Processor.Parser;
using ChangeFeed.Processor.Router;
using ChangeFeed.Processor.Settings;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Text;

namespace ChangeFeed.Processor
{
   public class ChangeProcessor
   {
      private readonly QueueServiceClient _queueServiceClient;
      private readonly ILogger<ChangeProcessor> _logger;
      private readonly AppSettings _settings;

      public ChangeProcessor(
         QueueServiceClient queueServiceClient,
         ILogger<ChangeProcessor> logger,
         IOptions<AppSettings> settings)
      {
         _queueServiceClient = queueServiceClient;
         _logger = logger;
         _settings = settings.Value;
      }

      [Function(nameof(CDCDataChangePipeline))]
      public async Task CDCDataChangePipeline(
         [EventHubTrigger("evh-product-dev", Connection = "eventhubnamespace_connectionstring", IsBatched = false)] byte[] eventData)
      {
         if (eventData.Length == 0)
            return;

         var parser = new ChangeFeedParser(JObject.Parse(Encoding.UTF8.GetString(eventData)));

         if (parser.GetChangeFeedType() == ChangeType.Table)
         {
            var database = parser.DatabaseInfo.Database;
            var schema = parser.TableInfo.Schema;
            var table = parser.TableInfo.Table;
            var operation = parser.Operation;
            var changedAt = parser.TableInfo.ChangedAt.ToString("O");

            _logger.LogInformation("Event from Change Feed received:");
            _logger.LogInformation("- Database: {Database}", database);
            _logger.LogInformation("- Object: {Schema}.{Table}", schema, table);
            _logger.LogInformation("- Operation: {Operation}", operation);
            _logger.LogInformation("- Captured At: {ChangedAt}", changedAt);

            var routes = _settings.ChangeFeedTargets
               .Where(setting => setting.Source.Database == database
                     && setting.Source.Schema == schema
                     && setting.Source.TableName == table
                     && setting.Triggers.Contains(operation.ToString()))
               .ToList();

            if (routes.Count != 0)
            {
               _logger.LogInformation("Routing event...");
               foreach (var route in routes)
               {
                  _logger.LogInformation("- Routing to Queue: {Queue}", route.Destination.AzureQueueName);

                  Fields fields;
                  if (parser.Operation == Operation.Insert || parser.Operation == Operation.Update)
                     fields = parser.After;
                  else
                     fields = parser.Before;

                  var routeMessage = RoutableMessageFactory.Create(route.Destination.RouteDatacontract, operation, fields);
                  var message = JsonConvert.SerializeObject(routeMessage);

                  await _queueServiceClient.CreateQueueAsync(route.Destination.AzureQueueName);
                  var queueClient = _queueServiceClient.GetQueueClient(route.Destination.AzureQueueName);
                  await queueClient.SendMessageAsync(message);
               }
            }
            else
            {
               _logger.LogInformation("- No Configured Routes: Ignoring event");
            }
         }

         await Task.Yield();
      }
   }
}
