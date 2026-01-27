import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../theme/app_theme.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedCourtId;
  String? _selectedTimeSlot;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  final List<String> _timeSlots = [
    '06:00 - 07:00', '07:00 - 08:00', '08:00 - 09:00', '09:00 - 10:00',
    '14:00 - 15:00', '15:00 - 16:00', '16:00 - 17:00', '17:00 - 18:00',
    '18:00 - 19:00', '19:00 - 20:00', '20:00 - 21:00',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadCourts();
    });
  }

  List<DateTime> _getNext7Days() {
    return List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final courts = booking.courts;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Image
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentGreen.withOpacity(0.8), AppTheme.primaryGreen],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: AppTheme.white),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_tennis, size: 64, color: AppTheme.white.withOpacity(0.8)),
                        SizedBox(height: 12),
                        Text('Đặt sân Pickleball', style: TextStyle(color: AppTheme.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Vợt Thủ Phố Núi', style: TextStyle(color: AppTheme.white.withOpacity(0.7), fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Selector
                    Text('Chọn ngày', style: TextStyle(color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final date = _getNext7Days()[index];
                          final isSelected = DateUtils.isSameDay(date, _selectedDate);
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDate = date),
                            child: Container(
                              width: 60,
                              margin: EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accentGreen : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected ? Border.all(color: AppTheme.lightGreen, width: 2) : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(DateFormat('E', 'vi').format(date).toUpperCase(),
                                    style: TextStyle(color: isSelected ? AppTheme.white : AppTheme.textMuted, fontSize: 12)),
                                  SizedBox(height: 4),
                                  Text('${date.day}',
                                    style: TextStyle(color: AppTheme.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Court Selector
                    Text('Chọn sân', style: TextStyle(color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: courts.map((court) {
                        final isSelected = _selectedCourtId == court.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCourtId = court.id),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.accentGreen : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(court.name, style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
                                Text('${currencyFormat.format(court.pricePerHour)}/h', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24),

                    // Time Selector
                    Text('Chọn giờ', style: TextStyle(color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _timeSlots.map((slot) {
                        final isSelected = _selectedTimeSlot == slot;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTimeSlot = slot),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.accentGreen : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected ? Border.all(color: AppTheme.lightGreen) : null,
                            ),
                            child: Text(slot, style: TextStyle(color: isSelected ? AppTheme.white : AppTheme.textMuted, fontSize: 13)),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Book Button
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng tiền', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      Text(
                        _selectedCourtId != null && _selectedTimeSlot != null
                          ? currencyFormat.format(courts.firstWhere((c) => c.id == _selectedCourtId).pricePerHour)
                          : '---',
                        style: TextStyle(color: AppTheme.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedCourtId != null && _selectedTimeSlot != null ? () => _confirmBooking(context) : null,
                    icon: Icon(Icons.sports_tennis),
                    label: Text('Đặt sân'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBooking(BuildContext context) async {
    final parts = _selectedTimeSlot!.split(' - ');
    final startHour = int.parse(parts[0].split(':')[0]);
    final endHour = int.parse(parts[1].split(':')[0]);

    final startTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, startHour);
    final endTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, endHour);

    final success = await context.read<BookingProvider>().book(_selectedCourtId!, startTime, endTime);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt sân thành công!'), backgroundColor: AppTheme.accentGreen),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt sân thất bại. Vui lòng kiểm tra số dư hoặc khung giờ.'), backgroundColor: Colors.red),
      );
    }
  }
}
