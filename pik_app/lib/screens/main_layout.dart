import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'booking/booking_screen.dart';
import 'tournament/tournament_list_screen.dart';
import 'admin/approve_deposit_screen.dart';
import 'admin/stats_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingScreen(),
    const TournamentListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.signalR.onNotificationReceived = (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Bạn có thông báo mới'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        if (data['type'] == 'DepositApproved') {
          Provider.of<WalletProvider>(context, listen: false).loadBalance();
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: AppTheme.surface,
            selectedItemColor: AppTheme.white,
            unselectedItemColor: AppTheme.textMuted,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Đặt sân'),
              BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Giải đấu'),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.surface,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.accentGreen, AppTheme.primaryGreen]),
              ),
              accountName: Text(auth.user?.fullName ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(auth.user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.white,
                child: Icon(Icons.person, size: 40, color: AppTheme.primaryDark),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: AppTheme.textSecondary),
              title: Text('Trang chủ', style: TextStyle(color: AppTheme.white)),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: AppTheme.textSecondary),
              title: Text('Đặt sân', style: TextStyle(color: AppTheme.white)),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_events, color: AppTheme.textSecondary),
              title: Text('Giải đấu', style: TextStyle(color: AppTheme.white)),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            if (auth.isAdmin) ...[
              Divider(color: AppTheme.textMuted),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 8),
                child: Text('Quản lý (Admin)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: AppTheme.gold),
                title: Text('Duyệt nạp tiền', style: TextStyle(color: AppTheme.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ApproveDepositScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.bar_chart, color: AppTheme.gold),
                title: Text('Thống kê doanh thu', style: TextStyle(color: AppTheme.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
                },
              ),
            ],
            const Spacer(),
            Divider(color: AppTheme.textMuted),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent),
              title: Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
              onTap: () => auth.logout(),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
