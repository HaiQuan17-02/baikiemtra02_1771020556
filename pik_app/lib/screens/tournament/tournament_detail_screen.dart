import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().loadTournamentDetail(widget.tournamentId);
    });
  }

  void _showUpdateScoreDialog(MatchModel match) {
    if (match.status == 'Finished') return;

    final score1Controller = TextEditingController(text: match.score1.toString());
    final score2Controller = TextEditingController(text: match.score2.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật tỉ số: ${match.roundName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${match.team1Name} vs ${match.team2Name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: score1Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Score 1'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: score2Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Score 2'))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final s1 = int.tryParse(score1Controller.text) ?? 0;
              final s2 = int.tryParse(score2Controller.text) ?? 0;
              if (s1 == s2) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tỉ số không được hòa')));
                return;
              }

              final success = await context.read<TournamentProvider>().updateMatchResult(match.id, s1, s2);
              if (success && mounted) {
                Navigator.pop(context);
                context.read<TournamentProvider>().loadTournamentDetail(widget.tournamentId); // Refresh
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final tournament = provider.selectedTournament;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (provider.isLoading || tournament == null) {
      return Scaffold(appBar: AppBar(title: const Text('Chi tiết giải đấu')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(tournament.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Phí tham gia:'), Text(currencyFormat.format(tournament.entryFee), style: const TextStyle(fontWeight: FontWeight.bold))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tổng giải thưởng:'), Text(currencyFormat.format(tournament.prizePool), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Trạng thái:'), Text(tournament.status, style: const TextStyle(fontWeight: FontWeight.bold))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Số lượng tham gia:'), Text('${tournament.participantCount}')]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Actions
            if (tournament.status == 'Open')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Check logic join
                    bool confirm = await showDialog(
                      context: context, 
                      builder: (c) => AlertDialog(
                        title: const Text('Xác nhận tham gia'),
                        content: Text('Bạn sẽ bị trừ ${currencyFormat.format(tournament.entryFee)} trong ví. Đồng ý không?'),
                        actions: [TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('Không')), ElevatedButton(onPressed: ()=>Navigator.pop(c,true), child: const Text('Đồng ý'))],
                      )
                    ) ?? false;
                    
                    if (confirm && mounted) {
                      final success = await provider.joinTournament(tournament.id);
                      if (success && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tham gia thành công')));
                      else if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tham gia thất bại (Có thể do không đủ tiền hoặc đã tham gia)')));
                    }
                  },
                  child: const Text('Đăng ký tham gia ngay'),
                ),
              ),
            
            if (isAdmin && tournament.status == 'Open')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () async {
                     await provider.generateSchedule(tournament.id);
                  },
                  child: const Text('Bốc thăm chia cặp (Admin)'),
                ),
              ),

            const SizedBox(height: 24),
            const Text('Danh sách tham gia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tournament.participants.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(tournament.participants[index].memberName),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Lịch thi đấu & Kết quả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tournament.matches.length,
              itemBuilder: (context, index) {
                final match = tournament.matches[index];
                return Card(
                  child: ListTile(
                    title: Text('${match.team1Name} vs ${match.team2Name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${match.roundName} - ${match.status == 'Finished' ? "Đã xong" : "Đang chờ"}'),
                    trailing: Text('${match.score1} - ${match.score2}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    onTap: isAdmin ? () => _showUpdateScoreDialog(match) : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
