namespace DatabaseSeeder.Models
{
   public class Product
   {
      public int ProductID { get; set; }
      public string Name { get; set; }
      public string Description { get; set; }

      // Navigation properties
      public ICollection<ProductTag> ProductTags { get; set; }
      public ICollection<Review> Reviews { get; set; }
   }
}
