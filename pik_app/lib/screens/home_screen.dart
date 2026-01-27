import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import 'booking/booking_screen.dart';
import 'tournament/tournament_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadBalance();
      context.read<WalletProvider>().loadTransactions();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getGreeting(), style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Xin chào, ${auth.user?.fullName ?? 'Bạn'}!',
                        style: const TextStyle(color: AppTheme.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: AppTheme.surfaceLight,
                    radius: 24,
                    child: Icon(Icons.person, color: AppTheme.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sân, giải đấu...',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: true,
                        ),
                        style: TextStyle(color: AppTheme.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Wallet Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accentGreen, AppTheme.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentGreen.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số dư ví', style: TextStyle(color: AppTheme.white.withOpacity(0.8), fontSize: 14)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(wallet.tier, style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(wallet.balanceAmount),
                      style: const TextStyle(color: AppTheme.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildWalletAction(Icons.add_circle_outline, 'Nạp tiền', () => _showDepositDialog(context)),
                        const SizedBox(width: 16),
                        _buildWalletAction(Icons.history, 'Lịch sử', () {}),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Quick Actions
              Text('Dịch vụ', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(Icons.sports_tennis, 'Đặt sân', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen()));
                  }),
                  _buildQuickAction(Icons.emoji_events, 'Giải đấu', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentListScreen()));
                  }),
                  _buildQuickAction(Icons.leaderboard, 'Bảng xếp hạng', () {}),
                  _buildQuickAction(Icons.group, 'Tìm đối', () {}),
                ],
              ),
              const SizedBox(height: 28),

              // Featured Courts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sân nổi bật', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: Text('Xem tất cả', style: TextStyle(color: AppTheme.accentGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCourtCard('Sân Pickleball A1', 'assets/court1.jpg', 4.8, 150000),
                    _buildCourtCard('Sân Pickleball B2', 'assets/court2.jpg', 4.5, 120000),
                    _buildCourtCard('Sân VIP Premium', 'assets/court3.jpg', 5.0, 250000),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.white, size: 18),
            SizedBox(width: 6),
            Text(label, style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.lightGreen, size: 28),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCourtCard(String name, String imagePath, double rating, double price) {
    return Container(
      width: 180,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(child: Icon(Icons.sports_tennis, size: 48, color: AppTheme.lightGreen)),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: AppTheme.gold, size: 16),
                    SizedBox(width: 4),
                    Text('$rating', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 4),
                Text(name, style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text('${currencyFormat.format(price)}/giờ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nạp tiền vào ví', style: TextStyle(color: AppTheme.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                labelText: 'Số tiền',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                prefixIcon: Icon(Icons.attach_money, color: AppTheme.accentGreen),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    await context.read<WalletProvider>().deposit(amount, '');
                    Navigator.pop(context);
                  }
                },
                child: Text('Gửi yêu cầu nạp tiền'),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
