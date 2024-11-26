namespace DatabaseSeeder.Models
{

   public class ProductTag
   {
      public int ProductID { get; set; }
      public int TagID { get; set; }

      // Navigation properties
      public Product Product { get; set; }
      public Tag Tag { get; set; }
   }
}
