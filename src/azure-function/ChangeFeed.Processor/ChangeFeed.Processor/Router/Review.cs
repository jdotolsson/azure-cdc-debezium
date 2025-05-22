using ChangeFeed.Processor.Parser;

namespace ChangeFeed.Processor.Router
{
   public class Review : IRoutable
   {
      public static Review Create(Fields fields)
      {
         return new Review
         {
            ProductId = int.Parse(fields["ProductID"].ToString() ?? throw new ArgumentException(null, nameof(fields))),
            ReviewID = int.Parse(fields["ReviewID"].ToString() ?? throw new ArgumentException(null, nameof(fields))),
            Rating = int.Parse(fields["Rating"].ToString() ?? throw new ArgumentException(null, nameof(fields))),
            Comment = fields["Comment"].ToString() ?? throw new ArgumentException(null, nameof(fields)),
         };
      }

      public required int ReviewID { get; set; }
      public required int ProductId { get; set; }
      public required int Rating { get; set; }
      public required string Comment { get; set; }
   }
}
