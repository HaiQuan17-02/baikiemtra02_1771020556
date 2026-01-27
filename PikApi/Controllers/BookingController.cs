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
    public class BookingController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<IdentityUser> _userManager;
        private readonly IHubContext<PcmHub> _hubContext;

        public BookingController(
            ApplicationDbContext context,
            UserManager<IdentityUser> userManager,
            IHubContext<PcmHub> hubContext)
        {
            _context = context;
            _userManager = userManager;
            _hubContext = hubContext;
        }

        /// <summary>
        /// GET /api/booking/courts
        /// Lấy danh sách sân
        /// </summary>
        [HttpGet("courts")]
        [AllowAnonymous]
        public async Task<ActionResult<List<object>>> GetCourts()
        {
            var courts = await _context.Courts
                .Where(c => c.IsActive)
                .Select(c => new
                {
                    c.Id,
                    c.Name,
                    c.PricePerHour,
                    c.Description
                })
                .ToListAsync();

            return Ok(courts);
        }

        /// <summary>
        /// GET /api/booking/calendar
        /// Lấy lịch đặt sân để hiển thị calendar
        /// </summary>
        [HttpGet("calendar")]
        [AllowAnonymous]
        public async Task<ActionResult<List<CourtCalendarResponse>>> GetCalendar(
            [FromQuery] DateTime from,
            [FromQuery] DateTime to)
        {
            var userId = _userManager.GetUserId(User);
            Member? currentMember = null;
            
            if (!string.IsNullOrEmpty(userId))
            {
                currentMember = await _context.Members
                    .FirstOrDefaultAsync(m => m.UserId == userId);
            }

            var courts = await _context.Courts
                .Where(c => c.IsActive)
                .Include(c => c.Bookings.Where(b => 
                    b.StartTime >= from && 
                    b.EndTime <= to &&
                    b.Status != BookingStatus.Cancelled))
                .ToListAsync();

            var result = courts.Select(c => new CourtCalendarResponse
            {
                CourtId = c.Id,
                CourtName = c.Name,
                Bookings = c.Bookings.Select(b => new BookingSlot
                {
                    BookingId = b.Id,
                    StartTime = b.StartTime,
                    EndTime = b.EndTime,
                    Status = b.Status.ToString(),
                    IsOwner = currentMember != null && b.MemberId == currentMember.Id
                }).ToList()
            }).ToList();

            return Ok(result);
        }

        /// <summary>
        /// POST /api/booking/book
        /// Đặt sân: Kiểm tra số dư -> Trừ tiền ví -> Tạo giao dịch Payment -> Tạo Booking
        /// Sử dụng Database Transaction để đảm bảo tính toàn vẹn
        /// </summary>
        [HttpPost("book")]
        public async Task<ActionResult<BookingResponse>> Book([FromBody] BookingRequest request)
        {
            var userId = _userManager.GetUserId(User);
            var member = await _context.Members
                .FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null)
                return NotFound("Không tìm thấy thông tin thành viên");

            // Validate thời gian
            if (request.StartTime >= request.EndTime)
                return BadRequest("Thời gian bắt đầu phải trước thời gian kết thúc");

            if (request.StartTime < DateTime.UtcNow)
                return BadRequest("Không thể đặt sân trong quá khứ");

            // Lấy thông tin sân
            var court = await _context.Courts
                .FirstOrDefaultAsync(c => c.Id == request.CourtId && c.IsActive);

            if (court == null)
                return NotFound("Không tìm thấy sân hoặc sân không hoạt động");

            // Tính giá tiền
            var duration = (request.EndTime - request.StartTime).TotalHours;
            var totalPrice = court.PricePerHour * (decimal)duration;

            // Bắt đầu Database Transaction
            using var dbTransaction = await _context.Database.BeginTransactionAsync();

            try
            {
                // 1. Kiểm tra số dư ví
                if (member.WalletBalance < totalPrice)
                {
                    return BadRequest($"Số dư ví không đủ. Cần: {totalPrice:N0}đ, Hiện có: {member.WalletBalance:N0}đ");
                }

                // 2. Kiểm tra trùng lịch (sử dụng Pessimistic Locking)
                var conflictBooking = await _context.Bookings
                    .Where(b => b.CourtId == request.CourtId &&
                                b.Status != BookingStatus.Cancelled &&
                                ((request.StartTime >= b.StartTime && request.StartTime < b.EndTime) ||
                                 (request.EndTime > b.StartTime && request.EndTime <= b.EndTime) ||
                                 (request.StartTime <= b.StartTime && request.EndTime >= b.EndTime)))
                    .FirstOrDefaultAsync();

                if (conflictBooking != null)
                {
                    return Conflict($"Sân đã được đặt trong khung giờ này ({conflictBooking.StartTime:HH:mm} - {conflictBooking.EndTime:HH:mm})");
                }

                // 3. Trừ tiền ví
                member.WalletBalance -= totalPrice;
                member.TotalSpent += totalPrice;

                // 4. Tạo giao dịch loại Payment
                var transaction = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -totalPrice, // Số âm vì là trừ tiền
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    Description = $"Thanh toán đặt sân {court.Name} ({request.StartTime:dd/MM/yyyy HH:mm} - {request.EndTime:HH:mm})",
                    CreatedDate = DateTime.UtcNow
                };
                _context.WalletTransactions.Add(transaction);
                await _context.SaveChangesAsync();

                // 5. Tạo Booking
                var booking = new Booking
                {
                    CourtId = request.CourtId,
                    MemberId = member.Id,
                    StartTime = request.StartTime,
                    EndTime = request.EndTime,
                    TotalPrice = totalPrice,
                    Status = BookingStatus.Confirmed,
                    TransactionId = transaction.Id
                };
                _context.Bookings.Add(booking);
                await _context.SaveChangesAsync();

                // Commit transaction
                await dbTransaction.CommitAsync();

                // 6. Gửi thông báo real-time: Lịch sân thay đổi
                await _hubContext.Clients.All.SendAsync("UpdateCalendar", new
                {
                    CourtId = court.Id,
                    CourtName = court.Name,
                    Booking = new BookingSlot
                    {
                        BookingId = booking.Id,
                        StartTime = booking.StartTime,
                        EndTime = booking.EndTime,
                        Status = booking.Status.ToString(),
                        IsOwner = false
                    },
                    Action = "Added"
                });

                return Ok(new BookingResponse
                {
                    Id = booking.Id,
                    CourtId = court.Id,
                    CourtName = court.Name,
                    MemberId = member.Id,
                    MemberName = member.FullName,
                    StartTime = booking.StartTime,
                    EndTime = booking.EndTime,
                    TotalPrice = booking.TotalPrice,
                    Status = booking.Status.ToString(),
                    CreatedAt = DateTime.UtcNow
                });
            }
            catch (DbUpdateConcurrencyException)
            {
                await dbTransaction.RollbackAsync();
                return Conflict("Có người khác đã đặt sân này. Vui lòng thử lại.");
            }
            catch (Exception)
            {
                await dbTransaction.RollbackAsync();
                throw;
            }
        }

        /// <summary>
        /// POST /api/booking/cancel/{id}
        /// Hủy booking và hoàn tiền (nếu đủ điều kiện)
        /// </summary>
        [HttpPost("cancel/{id}")]
        public async Task<ActionResult> CancelBooking(int id)
        {
            var userId = _userManager.GetUserId(User);
            var member = await _context.Members
                .FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null)
                return NotFound("Không tìm thấy thông tin thành viên");

            using var dbTransaction = await _context.Database.BeginTransactionAsync();

            try
            {
                var booking = await _context.Bookings
                    .Include(b => b.Court)
                    .FirstOrDefaultAsync(b => b.Id == id && b.MemberId == member.Id);

                if (booking == null)
                    return NotFound("Không tìm thấy booking");

                if (booking.Status == BookingStatus.Cancelled)
                    return BadRequest("Booking đã được hủy trước đó");

                // Tính tiền hoàn (100% nếu hủy trước 24h)
                var hoursBeforeStart = (booking.StartTime - DateTime.UtcNow).TotalHours;
                decimal refundRate = hoursBeforeStart >= 24 ? 1.0m : 0.5m;
                var refundAmount = booking.TotalPrice * refundRate;

                // Cập nhật trạng thái booking
                booking.Status = BookingStatus.Cancelled;

                // Hoàn tiền vào ví
                member.WalletBalance += refundAmount;

                // Tạo giao dịch hoàn tiền
                var refundTransaction = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = refundAmount,
                    Type = TransactionType.Deposit, // Dùng Deposit vì là cộng tiền
                    Status = TransactionStatus.Completed,
                    Description = $"Hoàn tiền hủy sân (Rate: {refundRate * 100}%)",
                    RelatedId = booking.Id.ToString(),
                    CreatedDate = DateTime.UtcNow
                };
                _context.WalletTransactions.Add(refundTransaction);

                await _context.SaveChangesAsync();
                await dbTransaction.CommitAsync();

                // Gửi thông báo real-time
                await _hubContext.Clients.All.SendAsync("UpdateCalendar", new
                {
                    CourtId = booking.CourtId,
                    CourtName = booking.Court?.Name,
                    BookingId = booking.Id,
                    Action = "Cancelled"
                });

                return Ok(new
                {
                    Message = $"Đã hủy booking. Hoàn tiền: {refundAmount:N0}đ ({refundRate * 100}%)",
                    RefundAmount = refundAmount,
                    NewBalance = member.WalletBalance
                });
            }
            catch (Exception)
            {
                await dbTransaction.RollbackAsync();
                throw;
            }
        }

        /// <summary>
        /// GET /api/booking/my-bookings
        /// Lấy danh sách booking của tôi
        /// </summary>
        [HttpGet("my-bookings")]
        public async Task<ActionResult<List<BookingResponse>>> GetMyBookings()
        {
            var userId = _userManager.GetUserId(User);
            var member = await _context.Members
                .FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null)
                return NotFound("Không tìm thấy thông tin thành viên");

            var bookings = await _context.Bookings
                .Include(b => b.Court)
                .Where(b => b.MemberId == member.Id)
                .OrderByDescending(b => b.StartTime)
                .Select(b => new BookingResponse
                {
                    Id = b.Id,
                    CourtId = b.CourtId,
                    CourtName = b.Court!.Name,
                    MemberId = member.Id,
                    MemberName = member.FullName,
                    StartTime = b.StartTime,
                    EndTime = b.EndTime,
                    TotalPrice = b.TotalPrice,
                    Status = b.Status.ToString()
                })
                .ToListAsync();

            return Ok(bookings);
        }
    }
}
