using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PikApi.Entities
{
    [Table("888_MatchRequestParticipants")]
    public class MatchRequestParticipant
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int MatchRequestId { get; set; }

        [ForeignKey("MatchRequestId")]
        public virtual MatchRequest? MatchRequest { get; set; }

        [Required]
        public int MemberId { get; set; }

        [ForeignKey("MemberId")]
        public virtual Member? Member { get; set; }

        public DateTime JoinedDate { get; set; } = DateTime.UtcNow;
    }
}
