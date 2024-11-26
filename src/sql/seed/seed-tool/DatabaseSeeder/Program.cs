using Bogus;
using DatabaseSeeder.Database;
using DatabaseSeeder.Extensions;
using DatabaseSeeder.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace DatabaseSeeder
{
   class Program
   {
      static void Main(string[] args)
      {
         var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                .Build();

         var seedOptions = new SeedOptions();
         configuration.GetSection("SeedOptions").Bind(seedOptions);

         int productCount = GetValidInput("Enter the number of categories to generate: ", seedOptions.ProductCount);
         int reviewMin = GetValidInput("Enter the number of reviews to generate(min value): ", seedOptions.ReviewCountMinValue);
         int reviewMax = GetValidInput("Enter the number of reviews to generate(max value): ", seedOptions.ReviewCountMaxValue);

         using (var context = new SeedContext(configuration))
         {
            var faker = new Faker();
            var rand = new Random();

            // Seed data for tags
            var productTagNames = new[]
            {
               "New Arrival",
               "Discounted",
               "Top-Rated",
               "Eco-Friendly",
               "Trending",
               "Best Seller"
            }.ToList();
            var reviewTagNames = new[]
            {
                "Verified Purchase",
                "Helpful",
                "Detailed",
                "Positive Feedback",
                "Constructive Criticism",
                "In-depth Review",
                "Concise",
                "Pros and Cons",
                "Highly Recommended",
                "Value for Money"
            }.ToList();

            context.ProductTags.ExecuteDelete();
            context.ReviewTags.ExecuteDelete();
            context.SaveChanges();

            var generatedProductTags = productTagNames.Select((name, index) => new Tag
            {
               Name = name
            }).ToList();

            context.Tags.AddRange(generatedProductTags);
            context.SaveChanges();

            var generatedReviewTags = reviewTagNames.Select((name, index) => new Tag
            {
               Name = name
            }).ToList();

            context.Tags.AddRange(generatedReviewTags);
            context.SaveChanges();

            // Generate Tags for Products
            var testProductTags = new Faker<Tag>()
               .CustomInstantiator(tag => generatedProductTags.PickRandom());

            // Generate Tags for Products
            var testReviewTags = new Faker<Tag>()
               .CustomInstantiator(tag => generatedProductTags.PickRandom());

            // Generate Reviews
            var testReviews = new Faker<Review>()
                .RuleFor(r => r.Rating, f => f.Random.Int(1, 5))
                .RuleFor(r => r.Comment, f => f.Rant.Review())
                .RuleFor(r => r.ReviewTags, f => testReviewTags.GenerateBetween(0, 5).DistinctBy(x => x.TagID).Select(rt => new ReviewTag { TagID = rt.TagID }).ToList());

            // Generate Products
            var testProducts = new Faker<Product>()
                .RuleFor(p => p.Name, f => f.Commerce.ProductName())
                .RuleFor(p => p.Description, f => f.Commerce.ProductDescription())
                .RuleFor(r => r.ProductTags, f => testProductTags.GenerateBetween(0, 5).DistinctBy(x => x.TagID).Select(rt => new ProductTag { TagID = rt.TagID }).ToList())
                .RuleFor(p => p.Reviews, f => testReviews.GenerateBetween(reviewMin, reviewMax))
                .FinishWith((f, p) =>
                {
                   //Console.WriteLine($"Product Created: {p.Name}");
                });

            // Generate 5 products
            var generatedProducts = testProducts.Generate(productCount);

            context.Products.AddRange(generatedProducts);
            context.SaveChanges();
         }

         Console.WriteLine("Database seeded successfully.");
      }

      static int GetValidInput(string prompt, int defaultValue)
      {
         int result;
         while (true)
         {
            Console.Write($"{prompt} (default: {defaultValue}): ");
            string? input = Console.ReadLine();
            if (string.IsNullOrEmpty(input))
            {
               return defaultValue;
            }
            if (int.TryParse(input, out result) && result >= 0)
            {
               break;
            }
            Console.WriteLine("Invalid input. Please enter a non-negative integer.");
         }
         return result;
      }
   }
}
