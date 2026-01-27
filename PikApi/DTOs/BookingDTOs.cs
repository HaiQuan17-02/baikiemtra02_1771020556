using System.ComponentModel.DataAnnotations;

namespace PikApi.DTOs
{
    // Request: Đặt sân
    public class BookingRequest
    {
        [Required]
        public int CourtId { get; set; }

        [Required]
        public DateTime StartTime { get; set; }

        [Required]
        public DateTime EndTime { get; set; }
    }

    // Response: Thông tin booking
    public class BookingResponse
    {
        public int Id { get; set; }
        public int CourtId { get; set; }
        public string CourtName { get; set; } = string.Empty;
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal TotalPrice { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }

    // Response: Lịch sân (cho Calendar view)
    public class CourtCalendarResponse
    {
        public int CourtId { get; set; }
        public string CourtName { get; set; } = string.Empty;
        public List<BookingSlot> Bookings { get; set; } = new();
    }

    public class BookingSlot
    {
        public int BookingId { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string Status { get; set; } = string.Empty;
        public bool IsOwner { get; set; }
    }
}
