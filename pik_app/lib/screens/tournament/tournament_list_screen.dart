import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'tournament_detail_screen.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().loadTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tournamentProvider = context.watch<TournamentProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Giải đấu', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () => _showCreateTournamentDialog(context),
              icon: Icon(Icons.add_circle, color: AppTheme.lightGreen, size: 28),
            ),
        ],
      ),
      body: tournamentProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
          : RefreshIndicator(
              color: AppTheme.accentGreen,
              onRefresh: () async => await context.read<TournamentProvider>().loadTournaments(),
              child: tournamentProvider.tournaments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 64, color: AppTheme.textMuted),
                          SizedBox(height: 16),
                          Text('Chưa có giải đấu nào', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: tournamentProvider.tournaments.length,
                      itemBuilder: (context, index) {
                        final t = tournamentProvider.tournaments[index];
                        return _buildTournamentCard(context, t);
                      },
                    ),
            ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, tournament) {
    final isOpen = tournament.status == 'Open';
    final isOngoing = tournament.status == 'Ongoing';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: tournament.id))),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOngoing
                ? [Color(0xFF2E7D32), Color(0xFF1B5E20)]
                : isOpen
                    ? [AppTheme.accentGreen, AppTheme.primaryGreen]
                    : [AppTheme.surfaceLight, AppTheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.emoji_events, size: 120, color: AppTheme.white.withOpacity(0.1)),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(tournament.name,
                          style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOpen ? AppTheme.gold : (isOngoing ? Colors.orange : Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOpen ? 'Đang mở' : (isOngoing ? 'Đang đấu' : 'Kết thúc'),
                          style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(Icons.calendar_today, DateFormat('dd/MM/yyyy').format(tournament.startDate)),
                      SizedBox(width: 16),
                      _buildInfoChip(Icons.people, '${tournament.participantCount} người'),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phí tham gia', style: TextStyle(color: AppTheme.white.withOpacity(0.7), fontSize: 12)),
                          Text(currencyFormat.format(tournament.entryFee),
                            style: TextStyle(color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Giải thưởng', style: TextStyle(color: AppTheme.white.withOpacity(0.7), fontSize: 12)),
                          Text(currencyFormat.format(tournament.prizePool),
                            style: TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.white.withOpacity(0.7)),
        SizedBox(width: 4),
        Text(text, style: TextStyle(color: AppTheme.white.withOpacity(0.7), fontSize: 13)),
      ],
    );
  }

  void _showCreateTournamentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final feeController = TextEditingController();
    final prizeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tạo giải đấu mới', style: TextStyle(color: AppTheme.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: TextStyle(color: AppTheme.white),
              decoration: InputDecoration(labelText: 'Tên giải', labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
            SizedBox(height: 12),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.white),
              decoration: InputDecoration(labelText: 'Phí tham gia (VND)', labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
            SizedBox(height: 12),
            TextField(
              controller: prizeController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.white),
              decoration: InputDecoration(labelText: 'Tổng giải thưởng (VND)', labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  await context.read<TournamentProvider>().createTournament(
                    nameController.text,
                    DateTime.now().add(Duration(days: 1)),
                    DateTime.now().add(Duration(days: 4)),
                    double.tryParse(feeController.text) ?? 0,
                    double.tryParse(prizeController.text) ?? 0,
                  );
                  Navigator.pop(context);
                },
                child: Text('Tạo giải đấu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
