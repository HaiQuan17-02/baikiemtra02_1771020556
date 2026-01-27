using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PikApi.Entities
{
    public enum MatchStatus
    {
        Scheduled,
        Finished
    }

    public enum WinningSide
    {
        None,
        Team1,
        Team2
    }

    [Table("888_Matches")]
    public class Match
    {
        [Key]
        public int Id { get; set; }

        public int TournamentId { get; set; }
        [ForeignKey("TournamentId")]
        public Tournament? Tournament { get; set; }

        [Required]
        [MaxLength(50)]
        public string RoundName { get; set; } = string.Empty; // Vòng 1, Tứ kết, Bán kết...

        public int? Team1_MemberId { get; set; }
        [ForeignKey("Team1_MemberId")]
        public Member? Team1 { get; set; }

        public int? Team2_MemberId { get; set; }
        [ForeignKey("Team2_MemberId")]
        public Member? Team2 { get; set; }

        public int Score1 { get; set; }
        public int Score2 { get; set; }

        public WinningSide Winner { get; set; } = WinningSide.None;

        public MatchStatus Status { get; set; } = MatchStatus.Scheduled;
        
        // Link tới match tiếp theo (nếu thắng sẽ đi đâu)
        public int? NextMatchId { get; set; }
    }
}
