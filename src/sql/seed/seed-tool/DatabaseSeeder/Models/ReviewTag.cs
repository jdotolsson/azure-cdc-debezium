namespace DatabaseSeeder.Models
{
   public class ReviewTag
   {
      public int ReviewID { get; set; }
      public int TagID { get; set; }

      // Navigation properties
      public Review Review { get; set; }
      public Tag Tag { get; set; }
   }
}
