using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;
using ChangeFeed.Processor.ChangeFeed.Search;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace ChangeFeed.Processor.ChangeFeed
{
   public class SearchIndexInitializer
   {
      private readonly ILogger _logger;
      private static readonly SemaphoreSlim _semaphore = new(1, 1);
      private readonly SearchIndexClient _searchIndexClient;

      public SearchIndexInitializer(
         ILoggerFactory loggerFactory,
         SearchIndexClient searchIndexClient)
      {
         _logger = loggerFactory.CreateLogger<SearchIndexInitializer>();
         _searchIndexClient = searchIndexClient;
      }

      [Function("SearchIndexInitializer")]
      public async Task Run([TimerTrigger("0 0 1 1 *", RunOnStartup = true)] TimerInfo myTimer, CancellationToken cancellationToken)
      {
         _logger.LogInformation("Startup check to see if indexes exists: {Now}", DateTime.Now);
         _logger.LogInformation("Timer past due: {IsPastDue}", myTimer.IsPastDue);

         await CreateOrRecreateIndexAsync("products-v1", typeof(ProductSearchIndexItem), ProductSearchIndexItem.ConfigureIndex, cancellationToken);
      }

      public async Task CreateOrRecreateIndexAsync(string indexName, Type datatype, Action<SearchIndex> ConfigureIndex, CancellationToken cancellationToken = default)
      {
         _logger.LogInformation("Acquiring semaphore for index: {indexName}", indexName);
         await _semaphore.WaitAsync(cancellationToken);
         try
         {
            _logger.LogInformation("Checking if index exists: {indexName}", indexName);
            var indexes = _searchIndexClient.GetIndexes(cancellationToken);

            if (indexes.Any(index => index.Name == indexName))
            {
               await _searchIndexClient.DeleteIndexAsync(indexName, cancellationToken: cancellationToken);
            }

            _logger.LogInformation("Creating index: {indexName}", indexName);
            var fieldBuilder = new FieldBuilder();
            var searchFields = fieldBuilder.Build(datatype);

            var index = new SearchIndex(indexName, searchFields);

            ConfigureIndex(index);

            await _searchIndexClient.CreateOrUpdateIndexAsync(index, cancellationToken: cancellationToken);
            _logger.LogInformation("Index created or updated: {indexName}", indexName);
         }
         catch (Exception ex)
         {
            _logger.LogError(ex, "Error creating or updating index: {indexName}", indexName);
            throw;
         }
         finally
         {
            _logger.LogInformation("Releasing semaphore for index: {indexName}", indexName);
            _semaphore.Release();
         }
      }
   }
}
