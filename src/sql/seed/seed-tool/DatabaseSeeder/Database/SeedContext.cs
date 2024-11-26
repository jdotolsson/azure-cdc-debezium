using Bogus;
using DatabaseSeeder.Models;
using EFCore.BulkExtensions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace DatabaseSeeder.Database
{
   internal class SeedContext(IConfigurationRoot configuration) : DbContext
   {
      public DbSet<Product> Products { get; set; }
      public DbSet<Review> Reviews { get; set; }
      public DbSet<Tag> Tags { get; set; }
      public DbSet<ProductTag> ProductTags { get; set; }
      public DbSet<ReviewTag> ReviewTags { get; set; }

      protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
      {
         var connectionString = configuration.GetConnectionString("DefaultConnection");
         optionsBuilder.UseSqlServer(connectionString);
      }

      protected override void OnModelCreating(ModelBuilder modelBuilder)
      {
         modelBuilder.Entity<ProductTag>()
             .HasKey(pt => new { pt.ProductID, pt.TagID });

         modelBuilder.Entity<ProductTag>()
             .HasOne(pt => pt.Product)
             .WithMany(p => p.ProductTags)
             .HasForeignKey(pt => pt.ProductID);

         modelBuilder.Entity<ProductTag>()
             .HasOne(pt => pt.Tag)
             .WithMany(t => t.ProductTags)
             .HasForeignKey(pt => pt.TagID);

         modelBuilder.Entity<ReviewTag>()
             .HasKey(rt => new { rt.ReviewID, rt.TagID });

         modelBuilder.Entity<ReviewTag>()
             .HasOne(rt => rt.Review)
             .WithMany(r => r.ReviewTags)
             .HasForeignKey(rt => rt.ReviewID);

         modelBuilder.Entity<ReviewTag>()
             .HasOne(rt => rt.Tag)
             .WithMany(t => t.ReviewTags)
             .HasForeignKey(rt => rt.TagID);
      }
   }

   internal static class Seeder
   {
      public static IEnumerable<T> SeedEntities<T>(SeedContext context, Func<T, string> propertySelector, int count, Func<int, Faker, T> entityGenerator) where T : class
      {
         var tempInstance = Activator.CreateInstance<T>();
         var IdColumnName = propertySelector(tempInstance);
         var lastEntity = context.Set<T>().OrderByDescending(e => EF.Property<int>(e, IdColumnName)).FirstOrDefault();
         int lastId = lastEntity != null ? (int?)lastEntity.GetType().GetProperty(IdColumnName)?.GetValue(lastEntity) ?? 1 : 1;
         var entities = new List<T>();
         var faker = new Faker();

         for (int i = lastId; i < (count + (int)lastId); i++)
         {
            entities.Add(entityGenerator(i, faker));
         }

         context.BulkInsert(entities);
         return entities;
      }
   }
}