using Azure.Search.Documents;
using ChangeFeed.Processor.Settings;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var builder = FunctionsApplication.CreateBuilder(args);
builder.Configuration.AddJsonFile("appsettings.json", false, reloadOnChange: true);
builder.ConfigureFunctionsWebApplication();

var searchIndexUri = builder.Configuration["ConnectionStrings:SearchIndexUri"];
ArgumentException.ThrowIfNullOrEmpty(searchIndexUri, "SearchIndexUri is a required setting in appsettings.json");
var searchIndexkey = builder.Configuration["ConnectionStrings:SearchIndexKey"];
ArgumentException.ThrowIfNullOrEmpty(searchIndexkey, "SearchIndexKey is a required setting in appsettings.json");

builder.Services.Configure<AppSettings>(builder.Configuration);
builder.Services.AddAzureClients(clientBuilder =>
{
   clientBuilder.AddQueueServiceClient(builder.Configuration["AzureWebJobsStorage"])
   .ConfigureOptions(options =>
   {
      options.Retry.Mode = Azure.Core.RetryMode.Exponential;
      options.Retry.MaxRetries = 5;
      options.Retry.Delay = TimeSpan.FromSeconds(2);

      options.MessageEncoding = Azure.Storage.Queues.QueueMessageEncoding.Base64;
   });

   clientBuilder.AddClient<Azure.Search.Documents.Indexes.SearchIndexClient, SearchClientOptions>(options =>
   {
      return new Azure.Search.Documents.Indexes.SearchIndexClient(new Uri(searchIndexUri), new Azure.AzureKeyCredential(searchIndexkey));
   });

   clientBuilder.AddClient<SearchClient, SearchClientOptions>(options =>
   {
      return new SearchClient(new Uri(searchIndexUri), "products-v1", new Azure.AzureKeyCredential(searchIndexkey));
   });
});

builder.Build().Run();
