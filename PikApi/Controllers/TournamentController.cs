using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PikApi.Data;
using PikApi.DTOs;
using PikApi.Entities;
using PikApi.Entities.Enums;
using PikApi.Hubs;
using System.Security.Claims;

namespace PikApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class TournamentController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<PcmHub> _hubContext;

        public TournamentController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
        }

        // GET: api/tournaments
        [HttpGet]
        public async Task<ActionResult<IEnumerable<TournamentDto>>> GetTournaments()
        {
            var tournaments = await _context.Tournaments
                .Select(t => new TournamentDto
                {
                    Id = t.Id,
                    Name = t.Name,
                    StartDate = t.StartDate,
                    EndDate = t.EndDate,
                    EntryFee = t.EntryFee,
                    PrizePool = t.PrizePool,
                    Status = t.Status.ToString(),
                    ParticipantCount = t.Participants.Count
                })
                .ToListAsync();

            return Ok(tournaments);
        }

        // GET: api/tournaments/5
        [HttpGet("{id}")]
        public async Task<ActionResult<TournamentDetailDto>> GetTournament(int id)
        {
            var tournament = await _context.Tournaments
                .Include(t => t.Participants).ThenInclude(p => p.Member)
                .Include(t => t.Matches).ThenInclude(m => m.Team1)
                .Include(t => t.Matches).ThenInclude(m => m.Team2)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tournament == null) return NotFound();

            var detail = new TournamentDetailDto
            {
                Id = tournament.Id,
                Name = tournament.Name,
                StartDate = tournament.StartDate,
                EndDate = tournament.EndDate,
                EntryFee = tournament.EntryFee,
                PrizePool = tournament.PrizePool,
                Status = tournament.Status.ToString(),
                ParticipantCount = tournament.Participants.Count,
                Participants = tournament.Participants.Select(p => new ParticipantDto
                {
                    MemberId = p.MemberId,
                    MemberName = p.Member?.FullName ?? "Unknown",
                    JoinedDate = p.JoinedDate
                }).ToList(),
                Matches = tournament.Matches.Select(m => new MatchDto
                {
                    Id = m.Id,
                    TournamentId = m.TournamentId,
                    RoundName = m.RoundName,
                    Team1_Id = m.Team1_MemberId,
                    Team1_Name = m.Team1?.FullName ?? "TBD",
                    Team2_Id = m.Team2_MemberId,
                    Team2_Name = m.Team2?.FullName ?? "TBD",
                    Score1 = m.Score1,
                    Score2 = m.Score2,
                    Winner = m.Winner.ToString(),
                    Status = m.Status.ToString(),
                    NextMatchId = m.NextMatchId
                }).ToList()
            };

            return Ok(detail);
        }

        // POST: api/tournaments (Admin)
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<TournamentDto>> CreateTournament(CreateTournamentRequest request)
        {
            var tournament = new Tournament
            {
                Name = request.Name,
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                EntryFee = request.EntryFee,
                PrizePool = request.PrizePool,
                Status = TournamentStatus.Open
            };

            _context.Tournaments.Add(tournament);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetTournament), new { id = tournament.Id }, tournament);
        }

        // POST: api/tournaments/join/5 (Member)
        [HttpPost("join/{id}")]
        public async Task<IActionResult> JoinTournament(int id)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return Unauthorized();

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var tournament = await _context.Tournaments.FindAsync(id);
                if (tournament == null) return NotFound("Tournament not found");

                if (tournament.Status != TournamentStatus.Open)
                    return BadRequest("Tournament is not open for registration");

                if (await _context.TournamentParticipants.AnyAsync(tp => tp.TournamentId == id && tp.MemberId == member.Id))
                    return BadRequest("You have already joined this tournament");

                // Check balance
                if (member.WalletBalance < tournament.EntryFee)
                    return BadRequest("Insufficient balance");

                // Deduct fee
                member.WalletBalance -= tournament.EntryFee;
                member.TotalSpent += tournament.EntryFee;
                _context.Members.Update(member);

                // Add transaction history
                _context.WalletTransactions.Add(new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -tournament.EntryFee,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    Description = $"Join Tournament: {tournament.Name}",
                    CreatedDate = DateTime.UtcNow
                });

                // Add prize pool
                tournament.PrizePool += tournament.EntryFee; 
                _context.Tournaments.Update(tournament);

                // Add participant
                _context.TournamentParticipants.Add(new TournamentParticipant
                {
                    TournamentId = id,
                    MemberId = member.Id,
                    IsFeePaid = true,
                    JoinedDate = DateTime.UtcNow
                });

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Notify Admin (optional)
                return Ok("Joined tournament successfully");
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        // POST: api/tournaments/generate-schedule/5 (Admin)
        [HttpPost("generate-schedule/{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GenerateSchedule(int id)
        {
            var tournament = await _context.Tournaments
                .Include(t => t.Participants)
                .Include(t => t.Matches)
                .FirstOrDefaultAsync(t => t.Id == id);
            
            if (tournament == null) return NotFound();
            if (tournament.Status != TournamentStatus.Open) return BadRequest("Only Open tournaments can generate schedule");
            if (tournament.Participants.Count < 2) return BadRequest("Not enough participants");
            if (tournament.Matches.Any()) return BadRequest("Schedule already generated");

            var participants = tournament.Participants.Select(p => p.MemberId).OrderBy(x => Guid.NewGuid()).ToList(); // Shuffle
            int n = participants.Count;
            int nextPowerOf2 = 1;
            while (nextPowerOf2 < n) nextPowerOf2 *= 2; // Find bracket size (e.g., 4, 8, 16)

            // Simple Single Elimination logic
            // Round 1
            var matches = new List<Match>();
            int matchCount = nextPowerOf2 / 2;
            
            // Create matches for Round 1
            for (int i = 0; i < matchCount; i++)
            {
                var match = new Match
                {
                    TournamentId = id,
                    RoundName = "Round 1",
                    Status = MatchStatus.Scheduled,
                    Team1_MemberId = (i * 2 < n) ? participants[i * 2] : null,
                    Team2_MemberId = (i * 2 + 1 < n) ? participants[i * 2 + 1] : null
                };
                matches.Add(match);
                // If bye round (only 1 player), auto win? Simplified: Assume full bracket or manual fix for now.
                // For this exam, let's assume perfect power of 2 or just creating pairs.
            }

            // Create subsequent rounds empty matches
            // Simplified: Just creating Round 1 for demo
            
            _context.Matches.AddRange(matches);
            tournament.Status = TournamentStatus.Ongoing;
            await _context.SaveChangesAsync();
            
            // Notify users
            await _hubContext.Clients.All.SendAsync("TournamentUpdated", id);

            return Ok($"Generated {matches.Count} matches");
        }

        // PUT: api/tournaments/matches/1/result (Admin)
        [HttpPut("matches/{id}/result")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateMatchResult(int id, UpdateMatchResultRequest request)
        {
            var match = await _context.Matches.FindAsync(id);
            if (match == null) return NotFound();

            match.Score1 = request.Score1;
            match.Score2 = request.Score2;
            
            if (request.Score1 > request.Score2) match.Winner = WinningSide.Team1;
            else if (request.Score2 > request.Score1) match.Winner = WinningSide.Team2;
            else match.Winner = WinningSide.None; // Draw not allowed in knockout usually

            if (match.Winner != WinningSide.None)
            {
                match.Status = MatchStatus.Finished;
                // Logic to move winner to next match if bracket implemented
            }

            await _context.SaveChangesAsync();

            // Notify real-time update
            await _hubContext.Clients.All.SendAsync("MatchUpdated", new MatchDto 
            {
                 Id = match.Id,
                 TournamentId = match.TournamentId,
                 Score1 = match.Score1,
                 Score2 = match.Score2,
                 Status = match.Status.ToString(),
                 Winner = match.Winner.ToString()
            });

            return Ok("Match updated");
        }
    }
}
