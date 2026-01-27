using PikApi.Entities;

namespace PikApi.DTOs
{
    public class TournamentDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal EntryFee { get; set; }
        public decimal PrizePool { get; set; }
        public string Status { get; set; }
        public int ParticipantCount { get; set; }
    }

    public class CreateTournamentRequest
    {
        public string Name { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal EntryFee { get; set; }
        public decimal PrizePool { get; set; }
    }

    public class TournamentDetailDto : TournamentDto
    {
        public List<ParticipantDto> Participants { get; set; }
        public List<MatchDto> Matches { get; set; }
    }

    public class ParticipantDto
    {
        public int MemberId { get; set; }
        public string MemberName { get; set; }
        public DateTime JoinedDate { get; set; }
    }

    public class MatchDto
    {
        public int Id { get; set; }
        public int TournamentId { get; set; }
        public string RoundName { get; set; }
        public int? Team1_Id { get; set; }
        public string Team1_Name { get; set; }
        public int? Team2_Id { get; set; }
        public string Team2_Name { get; set; }
        public int Score1 { get; set; }
        public int Score2 { get; set; }
        public string Winner { get; set; }
        public string Status { get; set; }
        public int? NextMatchId { get; set; }
    }

    public class UpdateMatchResultRequest
    {
        public int Score1 { get; set; }
        public int Score2 { get; set; }
    }
}
