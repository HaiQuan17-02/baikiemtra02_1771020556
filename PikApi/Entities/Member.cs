using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;
using PikApi.Entities.Enums;

namespace PikApi.Entities
{
    [Table("888_Members")]
    public class Member
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal WalletBalance { get; set; } = 0;

        public MemberTier Tier { get; set; } = MemberTier.Standard;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalSpent { get; set; } = 0;

        public DateTime JoinDate { get; set; } = DateTime.UtcNow;

        [MaxLength(200)]
        public string? AvatarUrl { get; set; }

        public double RankLevel { get; set; } = 3.0;

        public bool IsActive { get; set; } = true;

        // FK to Identity User
        [Required]
        public string UserId { get; set; } = string.Empty;

        [ForeignKey("UserId")]
        public virtual IdentityUser? User { get; set; }

        // Navigation properties
        public virtual ICollection<WalletTransaction> WalletTransactions { get; set; } = new List<WalletTransaction>();
        public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();
    }
}
