using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;

namespace ChangeFeed.Processor.ChangeFeed.Search
{
   internal class ProductSearchIndexItem
   {
      [SearchableField(IsKey = true)]
      public required string ProductId { get; set; }

      [SearchableField]
      public required string Name { get; set; }

      [SearchableField]
      public required string Description { get; set; }
      public ICollection<ReviewIndexItem> Reviews { get; set; } = [];

      public static void ConfigureIndex(SearchIndex index)
      {

      }
   }

   internal class ReviewIndexItem
   {
      [SimpleField]
      public int ReviewId { get; set; }

      [SimpleField]
      public required int Rating { get; set; }

      [SearchableField]
      public required string Comment { get; set; }
   }
}
