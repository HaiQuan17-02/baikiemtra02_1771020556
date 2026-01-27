using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PikApi.Entities
{
    public enum TournamentStatus
    {
        Open,       // Đang mở đăng ký
        Ongoing,    // Đang diễn ra
        Finished    // Đã kết thúc
    }

    [Table("888_Tournaments")]
    public class Tournament
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal EntryFee { get; set; } // Phí tham gia

        [Column(TypeName = "decimal(18,2)")]
        public decimal PrizePool { get; set; } // Tổng giải thưởng

        public TournamentStatus Status { get; set; } = TournamentStatus.Open;

        public ICollection<TournamentParticipant> Participants { get; set; } = new List<TournamentParticipant>();
        public ICollection<Match> Matches { get; set; } = new List<Match>();
    }
}
