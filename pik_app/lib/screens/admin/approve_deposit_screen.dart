import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';

class ApproveDepositScreen extends StatefulWidget {
  const ApproveDepositScreen({super.key});

  @override
  State<ApproveDepositScreen> createState() => _ApproveDepositScreenState();
}

class _ApproveDepositScreenState extends State<ApproveDepositScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadPendingTransactions();
    });
  }

  void _showProofImage(String description) {
    // Giả định tên file nằm trong description hoặc logic mock
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ảnh minh chứng'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 100, color: Colors.grey),
            Text('Đây là nơi hiển thị ảnh nạp tiền từ base64 hoặc URL storage.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Phê duyệt nạp tiền')),
      body: wallet.isLoading
          ? const Center(child: CircularProgressIndicator())
          : wallet.pendingTransactions.isEmpty
              ? const Center(child: Text('Không có yêu cầu nào đang chờ'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wallet.pendingTransactions.length,
                  itemBuilder: (context, index) {
                    final t = wallet.pendingTransactions[index];
                    return Card(
                      child: ListTile(
                        title: Text('Member ID: ${t.memberId}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Số tiền: ${currencyFormat.format(t.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            Text('Ngày: ${DateFormat('dd/MM HH:mm').format(t.createdDate)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                              onPressed: () => _showProofImage(t.description ?? ''),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final success = await wallet.approveDeposit(t.id);
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt thành công')));
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
