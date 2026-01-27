using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PikApi.Entities
{
    [Table("888_TournamentParticipants")]
    public class TournamentParticipant
    {
        [Key]
        public int Id { get; set; }

        public int TournamentId { get; set; }
        [ForeignKey("TournamentId")]
        public Tournament? Tournament { get; set; }

        public int MemberId { get; set; }
        [ForeignKey("MemberId")]
        public Member? Member { get; set; }

        public bool IsFeePaid { get; set; } // Đã đóng phí chưa
        public DateTime JoinedDate { get; set; } = DateTime.UtcNow;
    }
}
