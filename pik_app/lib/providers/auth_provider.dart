import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();
  
  UserInfo? _user;
  bool _isLoading = false;
  String? _error;

  UserInfo? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get error => _error;
  SignalRService get signalR => _signalRService;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.token != null) {
        await _apiService.saveToken(authResponse.token!);
        _user = authResponse.user;
        
        // Connect SignalR
        await _signalRService.connect();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = authResponse.message ?? 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(email, password, fullName);
      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.token != null) {
        await _apiService.saveToken(authResponse.token!);
        _user = authResponse.user;
        
        // Connect SignalR
        await _signalRService.connect();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = authResponse.message ?? 'Đăng ký thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      try {
        final response = await _apiService.getCurrentUser();
        _user = UserInfo.fromJson(response.data);
        await _signalRService.connect();
        notifyListeners();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    await _signalRService.disconnect();
    _user = null;
    notifyListeners();
  }

  void updateUserBalance(double newBalance) {
    if (_user != null) {
      _user = UserInfo(
        userId: _user!.userId,
        email: _user!.email,
        fullName: _user!.fullName,
        memberId: _user!.memberId,
        walletBalance: newBalance,
        tier: _user!.tier,
        roles: _user!.roles,
      );
      notifyListeners();
    }
  }
}
