using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PikApi.Entities.Enums;

namespace PikApi.Entities
{
    [Table("888_Bookings")]
    public class Booking
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CourtId { get; set; }

        [ForeignKey("CourtId")]
        public virtual Court? Court { get; set; }

        [Required]
        public int MemberId { get; set; }

        [ForeignKey("MemberId")]
        public virtual Member? Member { get; set; }

        [Required]
        public DateTime StartTime { get; set; }

        [Required]
        public DateTime EndTime { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPrice { get; set; }

        public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;

        public int? TransactionId { get; set; }

        [ForeignKey("TransactionId")]
        public virtual WalletTransaction? Transaction { get; set; }

        // Concurrency control - để tránh đặt trùng sân
        [Timestamp]
        public byte[] RowVersion { get; set; } = null!;

        // Advanced fields for recurring bookings
        public bool IsRecurring { get; set; } = false;

        [MaxLength(100)]
        public string? RecurrenceRule { get; set; }

        public int? ParentBookingId { get; set; }

        [ForeignKey("ParentBookingId")]
        public virtual Booking? ParentBooking { get; set; }

        public virtual ICollection<Booking> ChildBookings { get; set; } = new List<Booking>();
    }
}
