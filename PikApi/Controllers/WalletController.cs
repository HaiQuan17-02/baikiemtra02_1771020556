using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using PikApi.Data;
using PikApi.DTOs;
using PikApi.Entities;
using PikApi.Entities.Enums;
using PikApi.Hubs;

namespace PikApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class WalletController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<IdentityUser> _userManager;
        private readonly IHubContext<PcmHub> _hubContext;

        public WalletController(
            ApplicationDbContext context,
            UserManager<IdentityUser> userManager,
            IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _userManager = userManager;
            _hubContext = hubContext;
        }

        /// <summary>
        /// Lấy số dư ví của member hiện tại
        /// </summary>
        [HttpGet("balance")]
        public async Task<ActionResult<WalletBalanceResponse>> GetBalance()
        {
            var userId = _userManager.GetUserId(User);
            var member = await _context.Members
                .FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null)
                return NotFound("Không tìm thấy thông tin thành viên");

            return Ok(new WalletBalanceResponse
            {
                MemberId = member.Id,
                MemberName = member.FullName,
                Balance = member.WalletBalance,
                Tier = member.Tier.ToString()
            });
        }

        /// <summary>
        /// Lấy lịch sử giao dịch
        /// </summary>
        [HttpGet("transactions")]
        public async Task<ActionResult<List<WalletTransactionResponse>>> GetTransactions()
        {
            var userId = _userManager.GetUserId(User);
            var member = await _context.Members
                .FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null)
                return NotFound("Không tìm thấy thông tin thành viên");

            var transactions = await _context.WalletTransactions
                .Where(t => t.MemberId == member.Id)
                .OrderByDescending(t => t.CreatedDate)
                .Select(t => new WalletTransactionResponse
                {
                    Id = t.Id,
                    MemberId = t.MemberId,
                    Amount = t.Amount,
                    Type = t.Type.ToString(),
                    Status = t.Status.ToString(),
                    Description = t.Description,
                    CreatedDate = t.CreatedDate
                })
                .ToListAsync();

            return Ok(transactions);
        }

        /// <summary>
        /// POST /api/wallet/deposit
        /// Member gửi yêu cầu nạp tiền (nhận vào số tiền và Base64 string của ảnh)
        /// </summary>
        [HttpPost("deposit")]
        public async Task<ActionResult<WalletTransactionResponse>> Deposit([FromBody] DepositRequest request)
        {
            var userId = _userManager.GetUserId(User);
            var member = await _context.Members
                .FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null)
                return NotFound("Không tìm thấy thông tin thành viên");

            // Process proof image if provided
            string? imagePath = null;
            if (!string.IsNullOrEmpty(request.ProofImageBase64))
            {
                imagePath = await SaveProofImage(request.ProofImageBase64, member.Id);
            }

            // Tạo giao dịch nạp tiền với trạng thái Pending
            var transaction = new WalletTransaction
            {
                MemberId = member.Id,
                Amount = request.Amount,
                Type = TransactionType.Deposit,
                Status = TransactionStatus.Pending,
                Description = request.Description ?? (imagePath != null ? $"Yêu cầu nạp tiền - Ảnh: {imagePath}" : "Yêu cầu nạp tiền"),
                CreatedDate = DateTime.UtcNow
            };

            _context.WalletTransactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new WalletTransactionResponse
            {
                Id = transaction.Id,
                MemberId = transaction.MemberId,
                Amount = transaction.Amount,
                Type = transaction.Type.ToString(),
                Status = transaction.Status.ToString(),
                Description = transaction.Description,
                CreatedDate = transaction.CreatedDate
            });
        }

        /// <summary>
        /// PUT /api/wallet/approve/{id}
        /// Admin duyệt giao dịch, cộng tiền vào WalletBalance và đổi trạng thái sang Completed
        /// </summary>
        [HttpPut("approve/{id}")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<ActionResult<WalletTransactionResponse>> ApproveDeposit(int id)
        {
            using var dbTransaction = await _context.Database.BeginTransactionAsync();

            try
            {
                var transaction = await _context.WalletTransactions
                    .Include(t => t.Member)
                    .FirstOrDefaultAsync(t => t.Id == id);

                if (transaction == null)
                    return NotFound("Không tìm thấy giao dịch");

                if (transaction.Type != TransactionType.Deposit)
                    return BadRequest("Chỉ có thể duyệt giao dịch nạp tiền");

                if (transaction.Status != TransactionStatus.Pending)
                    return BadRequest("Giao dịch đã được xử lý trước đó");

                // Cập nhật trạng thái giao dịch
                transaction.Status = TransactionStatus.Completed;

                // Cộng tiền vào ví member
                var member = transaction.Member!;
                member.WalletBalance += transaction.Amount;

                await _context.SaveChangesAsync();
                await dbTransaction.CommitAsync();

                // Gửi thông báo real-time qua SignalR
                await _hubContext.Clients.User(member.UserId)
                    .SendAsync("ReceiveNotification", new
                    {
                        Type = "DepositApproved",
                        Message = $"Nạp tiền thành công: {transaction.Amount:N0}đ. Số dư mới: {member.WalletBalance:N0}đ",
                        Amount = transaction.Amount,
                        NewBalance = member.WalletBalance,
                        Timestamp = DateTime.UtcNow
                    });

                return Ok(new WalletTransactionResponse
                {
                    Id = transaction.Id,
                    MemberId = transaction.MemberId,
                    Amount = transaction.Amount,
                    Type = transaction.Type.ToString(),
                    Status = transaction.Status.ToString(),
                    Description = transaction.Description,
                    CreatedDate = transaction.CreatedDate
                });
            }
            catch (Exception)
            {
                await dbTransaction.RollbackAsync();
                throw;
            }
        }

        /// <summary>
        /// GET /api/wallet/admin/stats
        /// (Admin) Lấy thống kê doanh thu và số lượng member
        /// </summary>
        [HttpGet("admin/stats")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<ActionResult<AdminStatsResponse>> GetStats()
        {
            var today = DateTime.UtcNow.Date;
            var sevenDaysAgo = today.AddDays(-6);

            // 1. Tổng member
            var totalMembers = await _context.Members.CountAsync();

            // 2. Tổng doanh thu booking (tính các booking Confirmed/Completed)
            var bookings = await _context.Bookings
                .Where(b => b.Status != BookingStatus.Cancelled)
                .ToListAsync();
            
            var totalBookingRevenue = bookings.Sum(b => b.TotalPrice);
            var totalBookings = bookings.Count;

            // 3. Tổng dòng tiền nạp (tính các giao dịch Deposit/Completed)
            var totalDepositCashflow = await _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Completed)
                .SumAsync(t => t.Amount);

            // 4. Thống kê theo ngày (7 ngày gần nhất)
            var dailyStats = new List<DailyStatsDto>();
            for (int i = 0; i < 7; i++)
            {
                var date = sevenDaysAgo.AddDays(i);
                var nextDate = date.AddDays(1);

                var dayBookings = bookings.Where(b => b.StartTime >= date && b.StartTime < nextDate).ToList();
                var dayDeposits = await _context.WalletTransactions
                    .Where(t => t.Type == TransactionType.Deposit && 
                               t.Status == TransactionStatus.Completed &&
                               t.CreatedDate >= date && t.CreatedDate < nextDate)
                    .SumAsync(t => t.Amount);

                dailyStats.Add(new DailyStatsDto
                {
                    Date = date,
                    BookingRevenue = dayBookings.Sum(b => b.TotalPrice),
                    DepositCashflow = dayDeposits
                });
            }

            // 5. Thống kê theo sân
            var courtStats = bookings
                .Where(b => b.Court != null)
                .GroupBy(b => new { b.CourtId, b.Court!.Name })
                .Select(g => new CourtStatsDto
                {
                    CourtId = g.Key.CourtId,
                    CourtName = g.Key.Name,
                    Revenue = g.Sum(b => b.TotalPrice),
                    BookingCount = g.Count()
                })
                .OrderByDescending(c => c.Revenue)
                .ToList();

            return Ok(new AdminStatsResponse
            {
                TotalBookingRevenue = totalBookingRevenue,
                TotalDepositCashflow = totalDepositCashflow,
                TotalMembers = totalMembers,
                TotalBookings = totalBookings,
                DailyStats = dailyStats,
                CourtStats = courtStats
            });
        }

        /// <summary>
        /// GET /api/wallet/pending (Admin)
        /// Lấy danh sách giao dịch chờ duyệt
        /// </summary>
        [HttpGet("pending")]
        [Authorize(Roles = "Admin,Treasurer")]
        public async Task<ActionResult<List<WalletTransactionResponse>>> GetPendingTransactions()
        {
            var transactions = await _context.WalletTransactions
                .Where(t => t.Status == TransactionStatus.Pending && t.Type == TransactionType.Deposit)
                .OrderBy(t => t.CreatedDate)
                .Select(t => new WalletTransactionResponse
                {
                    Id = t.Id,
                    MemberId = t.MemberId,
                    Amount = t.Amount,
                    Type = t.Type.ToString(),
                    Status = t.Status.ToString(),
                    Description = t.Description,
                    CreatedDate = t.CreatedDate
                })
                .ToListAsync();

            return Ok(transactions);
        }

        private async Task<string> SaveProofImage(string base64Image, int memberId)
        {
            // Trong thực tế, lưu ảnh vào storage (Azure Blob, AWS S3, etc.)
            // Ở đây chỉ trả về tên file giả định
            var fileName = $"deposit_{memberId}_{DateTime.UtcNow:yyyyMMddHHmmss}.jpg";
            
            // TODO: Decode base64 và lưu file
            // var bytes = Convert.FromBase64String(base64Image);
            // await File.WriteAllBytesAsync(path, bytes);
            
            await Task.CompletedTask;
            return fileName;
        }
    }
}
