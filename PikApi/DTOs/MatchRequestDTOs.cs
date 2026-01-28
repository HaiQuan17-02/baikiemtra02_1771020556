using PikApi.Entities.Enums;

namespace PikApi.DTOs
{
    public class MatchRequestDto
    {
        public int Id { get; set; }
        public int CreatorMemberId { get; set; }
        public string CreatorName { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime PlayDate { get; set; }
        public string StartTime { get; set; } = string.Empty;
        public string EndTime { get; set; } = string.Empty;
        public int? CourtId { get; set; }
        public string? CourtName { get; set; }
        public int MaxPlayers { get; set; }
        public int CurrentPlayers { get; set; }
        public double SkillLevelMin { get; set; }
        public double SkillLevelMax { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; }
        public bool IsJoined { get; set; }
    }

    public class MatchRequestDetailDto : MatchRequestDto
    {
        public List<ParticipantInfoDto> Participants { get; set; } = new List<ParticipantInfoDto>();
    }

    public class ParticipantInfoDto
    {
        public int MemberId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public double RankLevel { get; set; }
        public DateTime JoinedDate { get; set; }
    }

    public class CreateMatchRequestDto
    {
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime PlayDate { get; set; }
        public string StartTime { get; set; } = string.Empty; // Format "HH:mm"
        public string EndTime { get; set; } = string.Empty;   // Format "HH:mm"
        public int? CourtId { get; set; }
        public int MaxPlayers { get; set; } = 4;
        public double SkillLevelMin { get; set; } = 2.0;
        public double SkillLevelMax { get; set; } = 5.0;
    }
}
