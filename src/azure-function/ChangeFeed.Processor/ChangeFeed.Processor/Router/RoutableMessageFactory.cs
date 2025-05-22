using ChangeFeed.Processor.Parser;

namespace ChangeFeed.Processor.Router
{
   public static class RoutableMessageFactory
   {
      public static RouteMessage<IRoutable> Create(string type, Operation operation, Fields fields)
      {
         return type switch
         {
            "Products" => new RouteMessage<IRoutable> { Operation = operation, Data = Product.Create(fields) },
            "Reviews" => new RouteMessage<IRoutable> { Operation = operation, Data = Review.Create(fields) },
            _ => throw new ArgumentException($"Unknown type: {type}", nameof(type)),
         };
      }
   }
}