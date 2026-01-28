import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  WalletBalance? _balance;
  List<WalletTransaction> _transactions = [];
  List<WalletTransaction> _pendingTransactions = [];
  AdminStats? _adminStats;
  bool _isLoading = false;
  String? _error;

  WalletBalance? get balance => _balance;
  List<WalletTransaction> get transactions => _transactions;
  List<WalletTransaction> get pendingTransactions => _pendingTransactions;
  AdminStats? get adminStats => _adminStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convenience getters for UI
  double get balanceAmount => _balance?.balance ?? 0;
  String get tier {
    final b = balanceAmount;
    if (b >= 5000000) return 'VIP';
    if (b >= 1000000) return 'Gold';
    if (b >= 500000) return 'Silver';
    return 'Bronze';
  }

  Future<void> loadAdminStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stats = await _apiService.getAdminStats();
      if (stats != null) {
        _adminStats = stats;
        _error = null;
      } else {
        _error = 'Không thể tải dữ liệu thống kê';
      }
    } catch (e) {
      _error = 'Lỗi kết nối máy chủ';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBalance() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getWalletBalance();
      _balance = WalletBalance.fromJson(response.data);
      _error = null;
    } catch (e) {
      _error = 'Lỗi tải số dư ví';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    try {
      final response = await _apiService.getTransactions();
      _transactions = (response.data as List)
          .map((e) => WalletTransaction.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Lỗi tải lịch sử giao dịch';
    }
  }

  Future<bool> deposit(double amount, String imageBase64, {String? description}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deposit(amount, imageBase64, description: description);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi gửi yêu cầu nạp tiền';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== Admin Functions ==========

  Future<void> loadPendingTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getPendingTransactions();
      _pendingTransactions = (response.data as List)
          .map((e) => WalletTransaction.fromJson(e))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Lỗi tải danh sách chờ duyệt';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> approveDeposit(int transactionId) async {
    try {
      await _apiService.approveDeposit(transactionId);
      // Remove from pending list
      _pendingTransactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi duyệt giao dịch';
      return false;
    }
  }

  // Statistics for Admin
  Map<String, double> getDailyRevenue() {
    final Map<String, double> revenue = {};
    for (var t in _transactions) {
      if (t.type == 'Deposit' && t.status == 'Completed') {
        final dateKey = '${t.createdDate.day}/${t.createdDate.month}';
        revenue[dateKey] = (revenue[dateKey] ?? 0) + t.amount;
      }
    }
    return revenue;
  }
}
