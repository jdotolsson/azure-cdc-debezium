namespace DatabaseSeeder.Models
{
   public class Review
   {
      public int ReviewID { get; set; }
      public int ProductID { get; set; }
      public int Rating { get; set; }
      public string Comment { get; set; }

      // Navigation properties
      public Product Product { get; set; }
      public ICollection<ReviewTag> ReviewTags { get; set; }
   }
}
