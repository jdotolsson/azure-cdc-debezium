using ChangeFeed.Processor.Parser;

namespace ChangeFeed.Processor.Router
{
   public class Product : IRoutable
   {
      public static Product Create(Fields fields)
      {
         return new Product
         {
            ProductId = int.Parse(fields["ProductID"].ToString() ?? throw new ArgumentException(null, nameof(fields))),
            Name = fields["Name"].ToString() ?? throw new ArgumentException(null, nameof(fields)),
            Description = fields["Description"].ToString() ?? throw new ArgumentException(null, nameof(fields))
         };
      }

      public required int ProductId { get; set; }
      public required string Name { get; set; }
      public required string Description { get; set; }
   }
}