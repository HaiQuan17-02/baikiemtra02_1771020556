using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace PikApi.Hubs
{
    /// <summary>
    /// SignalR Hub cho Pickleball Club Management
    /// Gửi thông báo real-time khi:
    /// - Nạp tiền thành công
    /// - Lịch sân thay đổi
    /// - Có kết quả trận đấu mới
    /// </summary>
    [Authorize]
    public class PcmHub : Hub
    {
        /// <summary>
        /// Gọi khi client kết nối
        /// </summary>
        public override async Task OnConnectedAsync()
        {
            // Thêm user vào group theo UserId để gửi thông báo cá nhân
            var userId = Context.UserIdentifier;
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
            }

            // Thêm vào group chung để nhận thông báo broadcast
            await Groups.AddToGroupAsync(Context.ConnectionId, "AllUsers");

            await base.OnConnectedAsync();
        }

        /// <summary>
        /// Gọi khi client ngắt kết nối
        /// </summary>
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.UserIdentifier;
            if (!string.IsNullOrEmpty(userId))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
            }

            await Groups.RemoveFromGroupAsync(Context.ConnectionId, "AllUsers");

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Client đăng ký xem trận đấu cụ thể (để nhận cập nhật score real-time)
        /// </summary>
        public async Task JoinMatchGroup(int matchId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"match_{matchId}");
        }

        /// <summary>
        /// Client rời khỏi group trận đấu
        /// </summary>
        public async Task LeaveMatchGroup(int matchId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"match_{matchId}");
        }

        /// <summary>
        /// Client đăng ký xem giải đấu cụ thể
        /// </summary>
        public async Task JoinTournamentGroup(int tournamentId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"tournament_{tournamentId}");
        }

        /// <summary>
        /// Client rời khỏi group giải đấu
        /// </summary>
        public async Task LeaveTournamentGroup(int tournamentId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"tournament_{tournamentId}");
        }

        // ========== Methods để gửi từ Server (gọi từ Controller/Service) ==========

        /// <summary>
        /// Gửi thông báo cho user cụ thể
        /// Sử dụng: await _hubContext.Clients.User(userId).SendAsync("ReceiveNotification", data);
        /// </summary>
        // ReceiveNotification - Client sẽ listen event này

        /// <summary>
        /// Gửi cập nhật lịch sân cho tất cả
        /// Sử dụng: await _hubContext.Clients.All.SendAsync("UpdateCalendar", data);
        /// </summary>
        // UpdateCalendar - Client sẽ listen event này

        /// <summary>
        /// Gửi cập nhật tỉ số trận đấu cho những người đang xem
        /// Sử dụng: await _hubContext.Clients.Group($"match_{matchId}").SendAsync("UpdateMatchScore", data);
        /// </summary>
        // UpdateMatchScore - Client sẽ listen event này
    }
}
