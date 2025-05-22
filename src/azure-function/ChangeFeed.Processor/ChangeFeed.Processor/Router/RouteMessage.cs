using ChangeFeed.Processor.Parser;

namespace ChangeFeed.Processor.Router
{
   public class RouteMessage<T> where T : IRoutable
   {
      public required Operation Operation { get; set; }
      public required T Data { get; set; }
   }

   public interface IRoutable
   {
   }
}