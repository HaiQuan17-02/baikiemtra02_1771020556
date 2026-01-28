import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import 'booking/booking_screen.dart';
import 'tournament/tournament_list_screen.dart';
import 'match/find_match_screen.dart';
import 'profile/profile_screen.dart';
import 'admin/stats_screen.dart';
import 'admin/court_management_screen.dart';
import 'admin/approve_deposit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().loadTournaments();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutBack,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
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

    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.menu, color: AppTheme.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getGreeting(), style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Xin chào, ${auth.user?.fullName.split(' ').last ?? 'Bạn'}!',
                            style: const TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.5), width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppTheme.surfaceLight,
                        radius: 20,
                        child: const Icon(Icons.person, color: AppTheme.white, size: 20),
                      ),
                    ),
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

              // News & Promotion Carousel
              SizedBox(
                height: 180,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildCarouselItem(
                      'assets/banners/promo1.png',
                      'KHUYẾN MÃI 20%',
                      'Đặt sân vào khung giờ vàng sáng sớm để nhận ưu đãi hấp dẫn.',
                      Colors.orange,
                    ),
                    _buildCarouselItem(
                      'assets/banners/tournament1.png',
                      'GIẢI ĐẤU QUỐC GIA',
                      'Giải Pickleball Toàn quốc 2026 chính thức mở đăng ký!',
                      AppTheme.gold,
                    ),
                    _buildTournamentPromo(context),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppTheme.accentGreen : AppTheme.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),

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
                  _buildQuickAction(Icons.group, 'Tìm đối', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FindMatchScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 32),

              // Admin Quick Actions
              if (auth.isAdmin) ...[
                Text('Quản lý hệ thống', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.accentGreen.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(Icons.bar_chart, 'Thống kê', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
                      }),
                      _buildQuickAction(Icons.settings, 'Các Sân', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CourtManagementScreen()));
                      }),
                      _buildQuickAction(Icons.account_balance_wallet, 'Duyệt nạp', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ApproveDepositScreen()));
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

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
      );
    }

  Widget _buildCarouselItem(String imagePath, String title, String subtitle, Color accentColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentPromo(BuildContext context) {
    final tournamentProvider = context.watch<TournamentProvider>();
    final upcoming = tournamentProvider.tournaments.isNotEmpty ? tournamentProvider.tournaments.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: AppTheme.gold, size: 28),
                const SizedBox(width: 10),
                Text('GIẢI ĐẤU SẮP TỚI', style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              upcoming != null ? upcoming.name : 'Chưa có giải đấu mới',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              upcoming != null 
                ? 'Khai mạc: ${DateFormat('dd/MM/yyyy').format(upcoming.startDate)}'
                : 'Hãy theo dõi thường xuyên để cập nhật!',
              style: TextStyle(color: AppTheme.white.withOpacity(0.7), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentListScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                minimumSize: const Size(100, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Xem chi tiết', style: TextStyle(fontSize: 12)),
            ),
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
}
