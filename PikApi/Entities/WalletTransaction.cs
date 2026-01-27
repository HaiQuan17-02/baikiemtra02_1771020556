using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PikApi.Entities.Enums;

namespace PikApi.Entities
{
    [Table("888_WalletTransactions")]
    public class WalletTransaction
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int MemberId { get; set; }

        [ForeignKey("MemberId")]
        public virtual Member? Member { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        public TransactionType Type { get; set; }

        public TransactionStatus Status { get; set; } = TransactionStatus.Pending;

        [MaxLength(500)]
        public string? Description { get; set; }

        [MaxLength(100)]
        public string? RelatedId { get; set; }

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    }
}
