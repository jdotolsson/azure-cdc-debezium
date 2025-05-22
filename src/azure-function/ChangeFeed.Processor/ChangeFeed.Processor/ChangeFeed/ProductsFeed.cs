using Azure.Search.Documents;
using ChangeFeed.Processor.ChangeFeed.Search;
using ChangeFeed.Processor.Router;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace ChangeFeed.Processor.ChangeFeed
{
   public class ProductsFeed
   {
      private readonly ILogger<ProductsFeed> _logger;
      private readonly SearchClient _searchClient;

      public ProductsFeed(ILogger<ProductsFeed> logger, SearchClient searchClient)
      {
         _logger = logger;
         _searchClient = searchClient;
      }

      [Function(nameof(ProductsFeed))]
      public async Task Run([QueueTrigger("products-feed")] string message)
      {
         var routeMessage = JsonConvert.DeserializeObject<RouteMessage<Product>>(message);

         if (routeMessage == null)
         {
            throw new InvalidOperationException("Failed to deserialize message");
         }

         if (routeMessage.Operation == Parser.Operation.Delete)
         {
            await _searchClient.DeleteDocumentsAsync(nameof(ProductSearchIndexItem.ProductId), [routeMessage.Data.ProductId.ToString()]);
            return;
         }

         var indexItem = new ProductSearchIndexItem
         {
            ProductId = routeMessage.Data.ProductId.ToString(),
            Name = routeMessage.Data.Name,
            Description = routeMessage.Data.Description
         };

         await _searchClient.MergeOrUploadDocumentsAsync([indexItem]);
      }
   }
}
