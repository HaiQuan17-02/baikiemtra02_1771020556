import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/match_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class FindMatchScreen extends StatefulWidget {
  const FindMatchScreen({super.key});

  @override
  State<FindMatchScreen> createState() => _FindMatchScreenState();
}

class _FindMatchScreenState extends State<FindMatchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchRequestProvider>().loadRequests();
      context.read<MatchRequestProvider>().loadMyData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchRequestProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Tìm Đối Chơi'),
        backgroundColor: AppTheme.primaryGreen,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGreen,
          labelColor: AppTheme.accentGreen,
          unselectedLabelColor: AppTheme.white.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Tìm đối'),
            Tab(text: 'Đã tham gia'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchList(provider.requests, provider.isLoading, provider.error),
          _buildMatchList([...provider.myRequests, ...provider.myJoinedMatches], provider.isLoading, provider.error),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRequestDialog(context),
        backgroundColor: AppTheme.accentGreen,
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
    );
  }

  Widget _buildMatchList(List<MatchRequest> matches, bool isLoading, String? error) {
    if (isLoading && matches.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
    }

    if (error != null && matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: AppTheme.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<MatchRequestProvider>().loadRequests();
                context.read<MatchRequestProvider>().loadMyData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis_outlined, size: 64, color: AppTheme.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('Chưa có trận nào', style: TextStyle(color: AppTheme.white.withOpacity(0.5))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<MatchRequestProvider>().loadRequests();
        await context.read<MatchRequestProvider>().loadMyData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final request = matches[index];
          return _buildMatchCard(request);
        },
      ),
    );
  }

  Widget _buildMatchCard(MatchRequest request) {
    final isFull = request.currentPlayers >= request.maxPlayers;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => _showMatchDetail(request.id),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFull ? Colors.orange.withOpacity(0.2) : AppTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFull ? 'Đã đầy' : 'Đang tìm',
                      style: TextStyle(color: isFull ? Colors.orange : AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(DateFormat('dd/MM/yyyy').format(request.playDate), style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text('${request.startTime} - ${request.endTime}', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(request.courtName ?? 'Chưa chọn sân', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group, size: 18, color: AppTheme.lightGreen),
                      const SizedBox(width: 6),
                      Text(
                        '${request.currentPlayers}/${request.maxPlayers} người',
                        style: const TextStyle(color: AppTheme.white, fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.leaderboard, size: 18, color: AppTheme.gold),
                      const SizedBox(width: 6),
                      Text(
                        'Lv ${request.skillLevelMin} - ${request.skillLevelMax}',
                        style: const TextStyle(color: AppTheme.white, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24, color: AppTheme.white),
              Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: AppTheme.accentGreen.withOpacity(0.3), child: const Icon(Icons.person, size: 14, color: AppTheme.white)),
                  const SizedBox(width: 8),
                  Text('Đăng bởi: ${request.creatorName}', style: TextStyle(color: AppTheme.white.withOpacity(0.7), fontSize: 12)),
                  const Spacer(),
                  if (request.isJoined)
                   const Text('Đã tham gia', style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold))
                  else
                   Text('Xem chi tiết', style: TextStyle(color: AppTheme.accentGreen))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMatchDetail(int id) {
    context.read<MatchRequestProvider>().loadDetail(id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MatchDetailSheet(id: id),
    );
  }

  void _showCreateRequestDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateMatchRequestSheet(),
    );
  }
}

class _MatchDetailSheet extends StatelessWidget {
  final int id;
  const _MatchDetailSheet({required this.id});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchRequestProvider>();
    final detail = provider.selectedDetail;
    final auth = context.read<AuthProvider>();

    if (provider.isLoading && detail == null) {
      return Container(
        height: 400,
        decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen)),
      );
    }

    if (detail == null) return const SizedBox();

    final isCreator = detail.creatorMemberId == auth.user?.memberId;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chi tiết trận đấu', style: TextStyle(color: AppTheme.white, fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.white)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.title, style: const TextStyle(color: AppTheme.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(detail.description ?? 'Không có mô tả', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.calendar_today, 'Ngày', DateFormat('dd/MM/yyyy').format(detail.playDate)),
                  _buildDetailRow(Icons.access_time, 'Thời gian', '${detail.startTime} - ${detail.endTime}'),
                  _buildDetailRow(Icons.location_on, 'Sân', detail.courtName ?? 'Chưa chọn sân'),
                  _buildDetailRow(Icons.group, 'Số người', '${detail.currentPlayers}/${detail.maxPlayers} người'),
                  _buildDetailRow(Icons.leaderboard, 'Trình độ', 'Lv ${detail.skillLevelMin} - ${detail.skillLevelMax}'),
                  const SizedBox(height: 24),
                  const Text('Người tham gia', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...detail.participants.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: AppTheme.surfaceLight, child: const Icon(Icons.person, color: AppTheme.white)),
                    title: Text(p.fullName, style: const TextStyle(color: AppTheme.white)),
                    subtitle: Text('Trình độ: Lv ${p.rankLevel}', style: TextStyle(color: AppTheme.textMuted)),
                    trailing: p.memberId == detail.creatorMemberId ? 
                      const Chip(label: Text('Chủ sân', style: TextStyle(fontSize: 10)), backgroundColor: AppTheme.accentGreen) : null,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: isCreator 
            ? ElevatedButton(
                onPressed: () async {
                  final success = await provider.cancelRequest(id);
                  if (success && context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hủy tin tìm đối'),
              )
            : detail.isJoined
              ? ElevatedButton(
                  onPressed: () async {
                    final success = await provider.leaveMatch(id);
                    if (success && context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceLight),
                  child: const Text('Rời khỏi trận'),
                )
              : ElevatedButton(
                  onPressed: detail.currentPlayers >= detail.maxPlayers ? null : () async {
                    final success = await provider.joinMatch(id);
                    if (success && context.mounted) Navigator.pop(context);
                  },
                  child: Text(detail.currentPlayers >= detail.maxPlayers ? 'Trận đã đầy' : 'Tham gia ngay'),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accentGreen),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CreateMatchRequestSheet extends StatefulWidget {
  const _CreateMatchRequestSheet();

  @override
  State<_CreateMatchRequestSheet> createState() => _CreateMatchRequestSheetState();
}

class _CreateMatchRequestSheetState extends State<_CreateMatchRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _playDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  int? _selectedCourtId;
  int _maxPlayers = 4;
  double _skillMin = 3.0;
  double _skillMax = 4.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = context.read<BookingProvider>();
      if (booking.courts.isEmpty) {
        booking.loadCourts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MatchRequestProvider>();
    final courts = context.watch<BookingProvider>().courts;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạo tin tìm đối', style: TextStyle(color: AppTheme.white, fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppTheme.white)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppTheme.white),
                      decoration: const InputDecoration(labelText: 'Tiêu đề (VD: Giao lưu sáng sớm)', labelStyle: TextStyle(color: AppTheme.textMuted)),
                      validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: AppTheme.white),
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Mô tả thêm', labelStyle: TextStyle(color: AppTheme.textMuted)),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày chơi', style: TextStyle(color: AppTheme.textMuted)),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_playDate), style: const TextStyle(color: AppTheme.white, fontSize: 16)),
                      trailing: const Icon(Icons.calendar_today, color: AppTheme.accentGreen),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _playDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) setState(() => _playDate = date);
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Từ', style: TextStyle(color: AppTheme.textMuted)),
                            subtitle: Text(_startTime.format(context), style: const TextStyle(color: AppTheme.white, fontSize: 16)),
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: _startTime);
                              if (time != null) setState(() => _startTime = time);
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Đến', style: TextStyle(color: AppTheme.textMuted)),
                            subtitle: Text(_endTime.format(context), style: const TextStyle(color: AppTheme.white, fontSize: 16)),
                            onTap: () async {
                              final time = await showTimePicker(context: context, initialTime: _endTime);
                              if (time != null) setState(() => _endTime = time);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCourtId,
                      dropdownColor: AppTheme.surface,
                      decoration: const InputDecoration(labelText: 'Sân (Tùy chọn)', labelStyle: TextStyle(color: AppTheme.textMuted)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Không cụ thể', style: TextStyle(color: AppTheme.white))),
                        ...courts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(color: AppTheme.white)))),
                      ],
                      onChanged: (v) => setState(() => _selectedCourtId = v),
                    ),
                    const SizedBox(height: 20),
                    _buildSliderRow('Số người tối đa', _maxPlayers.toDouble(), 2, 8, 1, (v) => setState(() => _maxPlayers = v.toInt())),
                    _buildSliderRow('Trình độ tối thiểu', _skillMin, 1.0, 6.0, 0.5, (v) => setState(() => _skillMin = v)),
                    _buildSliderRow('Trình độ tối đa', _skillMax, 1.0, 6.0, 0.5, (v) => setState(() => _skillMax = v)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      'title': _titleController.text,
                      'description': _descController.text,
                      'playDate': _playDate.toIso8601String(),
                      'startTime': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                      'endTime': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                      'courtId': _selectedCourtId,
                      'maxPlayers': _maxPlayers,
                      'skillLevelMin': _skillMin,
                      'skillLevelMax': _skillMax,
                    };
                    final success = await provider.createRequest(data);
                    if (success && context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Đăng tin tìm đối'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, double min, double max, double divisions, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted)),
            Text(value.toString(), style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / divisions).toInt(),
          activeColor: AppTheme.accentGreen,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
