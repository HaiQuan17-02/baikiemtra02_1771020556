using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PikApi.Entities.Enums;

namespace PikApi.Entities
{
    [Table("888_MatchRequests")]
    public class MatchRequest
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int CreatorMemberId { get; set; }

        [ForeignKey("CreatorMemberId")]
        public virtual Member? Creator { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Description { get; set; }

        public DateTime PlayDate { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }

        public int? CourtId { get; set; }
        
        [ForeignKey("CourtId")]
        public virtual Court? Court { get; set; }

        public int MaxPlayers { get; set; } = 4;
        
        public double SkillLevelMin { get; set; } = 2.0;
        public double SkillLevelMax { get; set; } = 5.0;

        public MatchRequestStatus Status { get; set; } = MatchRequestStatus.Open;

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        public virtual ICollection<MatchRequestParticipant> Participants { get; set; } = new List<MatchRequestParticipant>();
    }
}
