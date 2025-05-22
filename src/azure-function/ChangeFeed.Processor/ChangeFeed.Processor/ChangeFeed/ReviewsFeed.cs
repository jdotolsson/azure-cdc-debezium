using Azure.Search.Documents;
using Azure.Storage.Queues;
using ChangeFeed.Processor.ChangeFeed.Search;
using ChangeFeed.Processor.Router;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace ChangeFeed.Processor.ChangeFeed
{
   public class ReviewsFeed
   {
      private readonly ILogger<ReviewsFeed> _logger;
      private readonly SearchClient _searchClient;

      public ReviewsFeed(ILogger<ReviewsFeed> logger, SearchClient searchClient, QueueServiceClient queueServiceClient)
      {
         _logger = logger;
         _searchClient = searchClient;
      }

      [Function(nameof(ReviewsFeed))]
      public async Task Run([QueueTrigger("reviews-feed")] string message)
      {
         var routeMessage = JsonConvert.DeserializeObject<RouteMessage<Review>>(message)
             ?? throw new InvalidOperationException("Failed to deserialize message");

         var documentResponse = await _searchClient.GetDocumentAsync<ProductSearchIndexItem>(routeMessage.Data.ProductId.ToString());
         var document = documentResponse?.Value
             ?? throw new InvalidOperationException($"Document with ID {routeMessage.Data.ProductId} not found");

         if (routeMessage.Operation is Parser.Operation.Delete or Parser.Operation.Update)
         {
            var review = document.Reviews.FirstOrDefault(r => r.ReviewId == routeMessage.Data.ReviewID);
            if (review != null)
            {
               document.Reviews.Remove(review);
               if (routeMessage.Operation == Parser.Operation.Delete)
               {
                  await _searchClient.MergeOrUploadDocumentsAsync([document]);
                  return;
               }
            }
            else if (routeMessage.Operation == Parser.Operation.Delete)
            {
               return;
            }
         }

         if (routeMessage.Operation != Parser.Operation.Delete)
         {
            document.Reviews.Add(new ReviewIndexItem
            {
               ReviewId = routeMessage.Data.ReviewID,
               Rating = routeMessage.Data.Rating,
               Comment = routeMessage.Data.Comment
            });
         }

         await _searchClient.MergeOrUploadDocumentsAsync([document]);
      }
   }
}
