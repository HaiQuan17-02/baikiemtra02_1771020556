import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadBalance();
      context.read<WalletProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hồ sơ cá nhân', style: TextStyle(color: AppTheme.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.surfaceLight,
                    child: const Icon(Icons.person, size: 60, color: AppTheme.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'Hội viên',
                    style: const TextStyle(color: AppTheme.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Wallet Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentGreen, AppTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số dư ví', style: TextStyle(color: AppTheme.white.withOpacity(0.8), fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(wallet.tier.toUpperCase(), 
                          style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currencyFormat.format(wallet.balanceAmount),
                    style: const TextStyle(color: AppTheme.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          Icons.add_circle_outline, 
                          'Nạp tiền', 
                          () => _showDepositDialog(context),
                          Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          Icons.history, 
                          'Lịch sử', 
                          () {},
                          Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Information List
            _buildInfoCard(Icons.workspace_premium, 'Cấp độ hiện tại', 'Rank ${user?.rankLevel ?? 3.5}'), 
            const SizedBox(height: 12),
            _buildInfoCard(Icons.security, 'Bảo mật tài khoản', 'Đã xác thực'),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.help_outline, 'Hỗ trợ khách hàng', 'Liên hệ ngay'),
            
            const SizedBox(height: 40),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  auth.logout();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, color: Colors.orange),
                label: const Text('Đăng xuất', style: TextStyle(color: Colors.orange)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.accentGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    final amountController = TextEditingController();
    bool isNextStep = false;
    String transactionCode = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isNextStep) ...[
                const Text('Nạp tiền vào ví', style: TextStyle(color: AppTheme.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Nhập số tiền bạn muốn nạp vào tài khoản.', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.white, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Số tiền nạp (VNĐ)',
                    labelStyle: TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.payments, color: AppTheme.accentGreen),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.surfaceLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.accentGreen),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount >= 1000) {
                        setModalState(() {
                          isNextStep = true;
                          // Generate code: PIK + last 6 digits of current timestamp
                          transactionCode = 'PIK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Số tiền nạp tối thiểu là 1.000đ')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Tiếp tục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                const Text('Chuyển khoản qua QR', style: TextStyle(color: AppTheme.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      'https://img.vietqr.io/image/techcombank-200588886666-compact2.png?amount=${amountController.text}&addInfo=$transactionCode&accountName=VUONG%20TRONG%20HAI%20QUAN',
                      height: 250,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nội dung chuyển khoản:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              // In a real app, use Clipboard.setData
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép mã!')));
                            },
                            child: const Text('Sao chép', style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transactionCode,
                        style: const TextStyle(color: AppTheme.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠️ Quan trọng: Vui lòng nhập đúng nội dung chuyển khoản trên để được duyệt tiền tự động nhanh nhất.',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      final success = await context.read<WalletProvider>().deposit(amount, '', description: 'Mã: $transactionCode');
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yêu cầu đang được chờ duyệt!'), backgroundColor: AppTheme.accentGreen),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Tôi đã chuyển khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
