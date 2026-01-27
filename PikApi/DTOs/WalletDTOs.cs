using System.ComponentModel.DataAnnotations;

namespace PikApi.DTOs
{
    // Request: Nạp tiền vào ví
    public class DepositRequest
    {
        [Required]
        [Range(1000, 100000000, ErrorMessage = "Số tiền phải từ 1,000 đến 100,000,000")]
        public decimal Amount { get; set; }

        [Required]
        public string ProofImageBase64 { get; set; } = string.Empty;

        public string? Description { get; set; }
    }

    // Response: Thông tin giao dịch
    public class WalletTransactionResponse
    {
        public int Id { get; set; }
        public int MemberId { get; set; }
        public decimal Amount { get; set; }
        public string Type { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime CreatedDate { get; set; }
    }

    // Response: Số dư ví
    public class WalletBalanceResponse
    {
        public int MemberId { get; set; }
        public string MemberName { get; set; } = string.Empty;
        public decimal Balance { get; set; }
        public string Tier { get; set; } = string.Empty;
    }
}
