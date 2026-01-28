import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MatchRequestProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<MatchRequest> _requests = [];
  List<MatchRequest> _myRequests = [];
  List<MatchRequest> _myJoinedMatches = [];
  MatchRequestDetail? _selectedDetail;
  bool _isLoading = false;
  String? _error;

  List<MatchRequest> get requests => _requests;
  List<MatchRequest> get myRequests => _myRequests;
  List<MatchRequest> get myJoinedMatches => _myJoinedMatches;
  MatchRequestDetail? get selectedDetail => _selectedDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      _requests = await _apiService.getMatchRequests();
      _error = null;
    } catch (e) {
      _error = 'Lỗi tải danh sách tìm đối';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _myRequests = await _apiService.getMyMatchRequests();
      _myJoinedMatches = await _apiService.getMyJoinedMatches();
      _error = null;
    } catch (e) {
      _error = 'Lỗi tải dữ liệu cá nhân';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDetail(int id) async {
    _isLoading = true;
    _selectedDetail = null;
    notifyListeners();

    try {
      _selectedDetail = await _apiService.getMatchRequestDetail(id);
      _error = null;
    } catch (e) {
      _error = 'Lỗi tải chi tiết trận';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createRequest(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.createMatchRequest(data);
      if (success) {
        await loadRequests();
        await loadMyData();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Lỗi tạo tin tìm đối';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinMatch(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.joinMatchRequest(id);
      if (success) {
        await loadRequests();
        await loadMyData();
        await loadDetail(id);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Lỗi tham gia trận';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> leaveMatch(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.leaveMatchRequest(id);
      if (success) {
        await loadRequests();
        await loadMyData();
        await loadDetail(id);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Lỗi rời khỏi trận';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRequest(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _apiService.deleteMatchRequest(id);
      if (success) {
        await loadRequests();
        await loadMyData();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Lỗi hủy tin tìm đối';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
