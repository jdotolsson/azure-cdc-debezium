namespace DatabaseSeeder.Models
{
   public class Tag
   {
      public int TagID { get; set; }
      public string Name { get; set; }

      // Navigation properties
      public ICollection<ProductTag> ProductTags { get; set; }
      public ICollection<ReviewTag> ReviewTags { get; set; }
   }
}
