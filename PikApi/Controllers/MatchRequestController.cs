using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PikApi.Data;
using PikApi.DTOs;
using PikApi.Entities;
using PikApi.Entities.Enums;
using System.Security.Claims;

namespace PikApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class MatchRequestController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public MatchRequestController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/matchrequest
        [HttpGet]
        public async Task<ActionResult<IEnumerable<MatchRequestDto>>> GetMatchRequests()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            
            var requests = await _context.MatchRequests
                .Include(r => r.Creator)
                .Include(r => r.Court)
                .Include(r => r.Participants)
                .Where(r => r.Status == MatchRequestStatus.Open)
                .OrderByDescending(r => r.CreatedDate)
                .Select(r => new MatchRequestDto
                {
                    Id = r.Id,
                    CreatorMemberId = r.CreatorMemberId,
                    CreatorName = r.Creator != null ? r.Creator.FullName : "Unknown",
                    Title = r.Title,
                    Description = r.Description,
                    PlayDate = r.PlayDate,
                    StartTime = r.StartTime.ToString(@"hh\:mm"),
                    EndTime = r.EndTime.ToString(@"hh\:mm"),
                    CourtId = r.CourtId,
                    CourtName = r.Court != null ? r.Court.Name : null,
                    MaxPlayers = r.MaxPlayers,
                    CurrentPlayers = r.Participants.Count,
                    SkillLevelMin = r.SkillLevelMin,
                    SkillLevelMax = r.SkillLevelMax,
                    Status = r.Status.ToString(),
                    CreatedDate = r.CreatedDate,
                    IsJoined = member != null && r.Participants.Any(p => p.MemberId == member.Id)
                })
                .ToListAsync();

            return Ok(requests);
        }

        // GET: api/matchrequest/5
        [HttpGet("{id}")]
        public async Task<ActionResult<MatchRequestDetailDto>> GetMatchRequest(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            var r = await _context.MatchRequests
                .Include(r => r.Creator)
                .Include(r => r.Court)
                .Include(r => r.Participants).ThenInclude(p => p.Member)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (r == null) return NotFound();

            var detail = new MatchRequestDetailDto
            {
                Id = r.Id,
                CreatorMemberId = r.CreatorMemberId,
                CreatorName = r.Creator != null ? r.Creator.FullName : "Unknown",
                Title = r.Title,
                Description = r.Description,
                PlayDate = r.PlayDate,
                StartTime = r.StartTime.ToString(@"hh\:mm"),
                EndTime = r.EndTime.ToString(@"hh\:mm"),
                CourtId = r.CourtId,
                CourtName = r.Court != null ? r.Court.Name : null,
                MaxPlayers = r.MaxPlayers,
                CurrentPlayers = r.Participants.Count,
                SkillLevelMin = r.SkillLevelMin,
                SkillLevelMax = r.SkillLevelMax,
                Status = r.Status.ToString(),
                CreatedDate = r.CreatedDate,
                IsJoined = member != null && r.Participants.Any(p => p.MemberId == member.Id),
                Participants = r.Participants.Select(p => new ParticipantInfoDto
                {
                    MemberId = p.MemberId,
                    FullName = p.Member != null ? p.Member.FullName : "Unknown",
                    AvatarUrl = p.Member?.AvatarUrl,
                    RankLevel = p.Member?.RankLevel ?? 0,
                    JoinedDate = p.JoinedDate
                }).ToList()
            };

            return Ok(detail);
        }

        // POST: api/matchrequest
        [HttpPost]
        public async Task<ActionResult<MatchRequestDto>> CreateMatchRequest(CreateMatchRequestDto dto)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized();

            if (!TimeSpan.TryParse(dto.StartTime, out var startTime)) return BadRequest("Invalid StartTime format");
            if (!TimeSpan.TryParse(dto.EndTime, out var endTime)) return BadRequest("Invalid EndTime format");

            var request = new MatchRequest
            {
                CreatorMemberId = member.Id,
                Title = dto.Title,
                Description = dto.Description,
                PlayDate = dto.PlayDate,
                StartTime = startTime,
                EndTime = endTime,
                CourtId = dto.CourtId,
                MaxPlayers = dto.MaxPlayers,
                SkillLevelMin = dto.SkillLevelMin,
                SkillLevelMax = dto.SkillLevelMax,
                Status = MatchRequestStatus.Open,
                CreatedDate = DateTime.UtcNow
            };

            // Auto join the creator
            request.Participants.Add(new MatchRequestParticipant
            {
                MemberId = member.Id,
                JoinedDate = DateTime.UtcNow
            });

            _context.MatchRequests.Add(request);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetMatchRequest), new { id = request.Id }, new MatchRequestDto
            {
                Id = request.Id,
                CreatorMemberId = request.CreatorMemberId,
                CreatorName = member.FullName,
                Title = request.Title,
                Description = request.Description,
                PlayDate = request.PlayDate,
                StartTime = request.StartTime.ToString(@"hh\:mm"),
                EndTime = request.EndTime.ToString(@"hh\:mm"),
                CourtId = request.CourtId,
                MaxPlayers = request.MaxPlayers,
                CurrentPlayers = 1,
                SkillLevelMin = request.SkillLevelMin,
                SkillLevelMax = request.SkillLevelMax,
                Status = request.Status.ToString(),
                CreatedDate = request.CreatedDate,
                IsJoined = true
            });
        }

        // POST: api/matchrequest/join/5
        [HttpPost("join/{id}")]
        public async Task<IActionResult> JoinMatchRequest(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized();

            var request = await _context.MatchRequests
                .Include(r => r.Participants)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (request == null) return NotFound();
            if (request.Status != MatchRequestStatus.Open) return BadRequest("Match is no longer open");
            if (request.Participants.Any(p => p.MemberId == member.Id)) return BadRequest("Already joined");
            if (request.Participants.Count >= request.MaxPlayers) return BadRequest("Match is full");

            var participant = new MatchRequestParticipant
            {
                MatchRequestId = id,
                MemberId = member.Id,
                JoinedDate = DateTime.UtcNow
            };

            _context.MatchRequestParticipants.Add(participant);

            if (request.Participants.Count + 1 >= request.MaxPlayers)
            {
                request.Status = MatchRequestStatus.Full;
            }

            await _context.SaveChangesAsync();
            return Ok();
        }

        // POST: api/matchrequest/leave/5
        [HttpPost("leave/{id}")]
        public async Task<IActionResult> LeaveMatchRequest(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized();

            var participant = await _context.MatchRequestParticipants
                .FirstOrDefaultAsync(p => p.MatchRequestId == id && p.MemberId == member.Id);

            if (participant == null) return BadRequest("Not a participant");

            var request = await _context.MatchRequests.FindAsync(id);
            if (request != null && request.CreatorMemberId == member.Id)
            {
                return BadRequest("Creator cannot leave. Please cancel the request instead.");
            }

            _context.MatchRequestParticipants.Remove(participant);

            if (request != null && request.Status == MatchRequestStatus.Full)
            {
                request.Status = MatchRequestStatus.Open;
            }

            await _context.SaveChangesAsync();
            return Ok();
        }

        // DELETE: api/matchrequest/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteMatchRequest(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized();

            var request = await _context.MatchRequests.FindAsync(id);
            if (request == null) return NotFound();

            if (request.CreatorMemberId != member.Id && !User.IsInRole("Admin"))
            {
                return Forbid();
            }

            request.Status = MatchRequestStatus.Cancelled;
            await _context.SaveChangesAsync();

            return Ok();
        }

        // GET: api/matchrequest/my-requests
        [HttpGet("my-requests")]
        public async Task<ActionResult<IEnumerable<MatchRequestDto>>> GetMyRequests()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized();

            var requests = await _context.MatchRequests
                .Include(r => r.Creator)
                .Include(r => r.Court)
                .Include(r => r.Participants)
                .Where(r => r.CreatorMemberId == member.Id)
                .OrderByDescending(r => r.CreatedDate)
                .Select(r => new MatchRequestDto
                {
                    Id = r.Id,
                    CreatorMemberId = r.CreatorMemberId,
                    CreatorName = r.Creator != null ? r.Creator.FullName : "Unknown",
                    Title = r.Title,
                    Description = r.Description,
                    PlayDate = r.PlayDate,
                    StartTime = r.StartTime.ToString(@"hh\:mm"),
                    EndTime = r.EndTime.ToString(@"hh\:mm"),
                    CourtId = r.CourtId,
                    CourtName = r.Court != null ? r.Court.Name : null,
                    MaxPlayers = r.MaxPlayers,
                    CurrentPlayers = r.Participants.Count,
                    SkillLevelMin = r.SkillLevelMin,
                    SkillLevelMax = r.SkillLevelMax,
                    Status = r.Status.ToString(),
                    CreatedDate = r.CreatedDate,
                    IsJoined = true
                })
                .ToListAsync();

            return Ok(requests);
        }

        // GET: api/matchrequest/my-joined
        [HttpGet("my-joined")]
        public async Task<ActionResult<IEnumerable<MatchRequestDto>>> GetMyJoined()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized();

            var requests = await _context.MatchRequests
                .Include(r => r.Creator)
                .Include(r => r.Court)
                .Include(r => r.Participants)
                .Where(r => r.Participants.Any(p => p.MemberId == member.Id) && r.CreatorMemberId != member.Id)
                .OrderByDescending(r => r.CreatedDate)
                .Select(r => new MatchRequestDto
                {
                    Id = r.Id,
                    CreatorMemberId = r.CreatorMemberId,
                    CreatorName = r.Creator != null ? r.Creator.FullName : "Unknown",
                    Title = r.Title,
                    Description = r.Description,
                    PlayDate = r.PlayDate,
                    StartTime = r.StartTime.ToString(@"hh\:mm"),
                    EndTime = r.EndTime.ToString(@"hh\:mm"),
                    CourtId = r.CourtId,
                    CourtName = r.Court != null ? r.Court.Name : null,
                    MaxPlayers = r.MaxPlayers,
                    CurrentPlayers = r.Participants.Count,
                    SkillLevelMin = r.SkillLevelMin,
                    SkillLevelMax = r.SkillLevelMax,
                    Status = r.Status.ToString(),
                    CreatedDate = r.CreatedDate,
                    IsJoined = true
                })
                .ToListAsync();

            return Ok(requests);
        }
    }
}
