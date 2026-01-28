import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class CourtManagementScreen extends StatefulWidget {
  const CourtManagementScreen({super.key});

  @override
  State<CourtManagementScreen> createState() => _CourtManagementScreenState();
}

class _CourtManagementScreenState extends State<CourtManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadAdminCourts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final courts = booking.adminCourts;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Quản lý Sân', style: TextStyle(color: AppTheme.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: booking.isLoading && courts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
          : booking.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(booking.error!, style: const TextStyle(color: AppTheme.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => booking.loadAdminCourts(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
              onRefresh: () => booking.loadAdminCourts(),
              color: AppTheme.accentGreen,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courts.length,
                itemBuilder: (context, index) {
                  final court = courts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: court.isActive ? AppTheme.accentGreen.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        court.name,
                        style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            court.isActive ? 'Đang hoạt động' : 'Đang tạm dừng',
                            style: TextStyle(
                              color: court.isActive ? AppTheme.accentGreen : Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            court.description ?? 'Không có mô tả',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: court.isActive,
                        onChanged: (value) async {
                          final success = await booking.toggleCourtStatus(court.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value ? 'Đã bật sân ${court.name}' : 'Đã tắt sân ${court.name}'),
                                backgroundColor: value ? AppTheme.accentGreen : Colors.orange,
                              ),
                            );
                          }
                        },
                        activeColor: AppTheme.accentGreen,
                        activeTrackColor: AppTheme.accentGreen.withOpacity(0.3),
                        inactiveThumbColor: Colors.redAccent,
                        inactiveTrackColor: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
