using Microsoft.AspNetCore.Identity;
using PikApi.Entities;
using PikApi.Entities.Enums;

namespace PikApi.Data
{
    public static class DataSeeder
    {
        public static async Task SeedData(IServiceProvider serviceProvider)
        {
            var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();
            var userManager = serviceProvider.GetRequiredService<UserManager<IdentityUser>>();
            var context = serviceProvider.GetRequiredService<ApplicationDbContext>();

            // 1. Seed Roles
            string[] roleNames = { "Admin", "Treasurer", "Member" };
            foreach (var roleName in roleNames)
            {
                if (!await roleManager.RoleExistsAsync(roleName))
                {
                    await roleManager.CreateAsync(new IdentityRole(roleName));
                }
            }

            // 2. Seed Admin User
            var adminEmail = "admin@pcm.com";
            var adminUser = await userManager.FindByEmailAsync(adminEmail);
            if (adminUser == null)
            {
                var newAdmin = new IdentityUser
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    EmailConfirmed = true
                };
                var result = await userManager.CreateAsync(newAdmin, "Admin@123");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(newAdmin, "Admin");
                    
                    // Create Member Profile for Admin
                    var member = new Member
                    {
                        UserId = newAdmin.Id,
                        FullName = "System Administrator",
                        WalletBalance = 99999999, // Rich admin
                        Tier = MemberTier.Diamond,
                        JoinDate = DateTime.UtcNow,
                        IsActive = true
                    };
                    context.Members.Add(member);
                    await context.SaveChangesAsync();
                }
            }

            // 3. Seed Treasurer User
            var treasurerEmail = "cash@pcm.com";
            if (await userManager.FindByEmailAsync(treasurerEmail) == null)
            {
                var newTreasurer = new IdentityUser
                {
                    UserName = treasurerEmail,
                    Email = treasurerEmail,
                    EmailConfirmed = true
                };
                var result = await userManager.CreateAsync(newTreasurer, "Admin@123");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(newTreasurer, "Treasurer");
                    
                    context.Members.Add(new Member
                    {
                        UserId = newTreasurer.Id,
                        FullName = "Thủ Quỹ",
                        WalletBalance = 0,
                        Tier = MemberTier.Gold,
                        JoinDate = DateTime.UtcNow,
                        IsActive = true
                    });
                    await context.SaveChangesAsync();
                }
            }

            // 4. Seed Courts
            if (!context.Courts.Any())
            {
                var courts = new List<Court>
                {
                    new Court { Name = "Sân 1 - VIP", PricePerHour = 200000, Description = "Sân thảm chuẩn quốc tế, có mái che", IsActive = true },
                    new Court { Name = "Sân 2 - Tiêu chuẩn", PricePerHour = 150000, Description = "Sân ngoài trời, thoáng mát", IsActive = true },
                    new Court { Name = "Sân 3 - Tiêu chuẩn", PricePerHour = 150000, Description = "Sân ngoài trời", IsActive = true },
                    new Court { Name = "Sân 4 - Tập luyện", PricePerHour = 100000, Description = "Sân tập cho người mới", IsActive = true },
                };
                context.Courts.AddRange(courts);
                await context.SaveChangesAsync();
            }
        }
    }
}
