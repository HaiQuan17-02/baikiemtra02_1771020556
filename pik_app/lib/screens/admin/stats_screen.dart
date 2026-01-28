import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final stats = wallet.adminStats;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Thống kê doanh thu', style: TextStyle(color: AppTheme.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: wallet.isLoading && stats == null // Modified condition for initial loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
          : wallet.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(wallet.error!, style: const TextStyle(color: AppTheme.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => wallet.loadAdminStats(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : stats == null || stats.dailyStats.isEmpty
                  ? const Center(child: Text('Không có dữ liệu thống kê', style: TextStyle(color: AppTheme.textMuted)))
                  : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Cards
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('D.Thu Sân', currencyFormat.format(stats.totalBookingRevenue), Icons.sports_tennis, Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('Tiền Nạp', currencyFormat.format(stats.totalDepositCashflow), Icons.account_balance_wallet, AppTheme.accentGreen)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Tổng Đặt Sân', stats.totalBookings.toString(), Icons.calendar_today, Colors.orange)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('Hội Viên', stats.totalMembers.toString(), Icons.people, Colors.purple)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      const Text('Biểu đồ tăng trưởng (7 ngày)', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      
                      // Chart
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxY(stats.dailyStats),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  String category = rodIndex == 0 ? 'Booking' : 'Nạp tiền';
                                  return BarTooltipItem(
                                    '$category\n${currencyFormat.format(rod.toY)}',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < stats.dailyStats.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('dd/MM').format(stats.dailyStats[index].date),
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(stats.dailyStats.length, (index) {
                              final day = stats.dailyStats[index];
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(toY: day.bookingRevenue, color: Colors.blue, width: 8, borderRadius: BorderRadius.circular(4)),
                                  BarChartRodData(toY: day.depositCashflow, color: AppTheme.accentGreen, width: 8, borderRadius: BorderRadius.circular(4)),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegend(Colors.blue, 'D.Thu Sân'),
                          const SizedBox(width: 20),
                          _buildLegend(AppTheme.accentGreen, 'Tiền Nạp'),
                        ],
                      ),

                      const SizedBox(height: 32),
                      const Text('Doanh thu theo sân', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...stats.courtStats.map((court) => _buildCourtRevenueRow(court)),

                      const SizedBox(height: 32),
                      const Text('Chi tiết doanh thu ngày', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // List
                      ...stats.dailyStats.reversed.map((day) => _buildDailyRow(day)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  double _getMaxY(List<DailyStats> dailyStats) {
    double max = 0;
    for (var day in dailyStats) {
      if (day.bookingRevenue > max) max = day.bookingRevenue;
      if (day.depositCashflow > max) max = day.depositCashflow;
    }
    return max == 0 ? 1000 : max * 1.2;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRow(DailyStats day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEEE, dd MMMM').format(day.date), style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Tiền nạp: ${currencyFormat.format(day.depositCashflow)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          Text(
            currencyFormat.format(day.bookingRevenue),
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtRevenueRow(CourtStats court) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports_tennis, color: AppTheme.accentGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(court.courtName, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                Text('${court.bookingCount} lượt đặt', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(
            currencyFormat.format(court.revenue),
            style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }
}
