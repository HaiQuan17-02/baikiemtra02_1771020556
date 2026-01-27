import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:5054/api'; // Android emulator
  static const String baseUrl = 'http://localhost:5054/api'; // Windows/iOS
  
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add JWT Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired - clear and redirect to login
            await _storage.delete(key: 'jwt_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ========== Auth ==========
  
  Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(String email, String password, String fullName) async {
    return await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/auth/me');
  }

  // ========== Wallet ==========

  Future<Response> getWalletBalance() async {
    return await _dio.get('/wallet/balance');
  }

  Future<Response> getTransactions() async {
    return await _dio.get('/wallet/transactions');
  }

  Future<Response> deposit(double amount, String proofImageBase64, {String? description}) async {
    return await _dio.post('/wallet/deposit', data: {
      'amount': amount,
      'proofImageBase64': proofImageBase64,
      'description': description,
    });
  }

  Future<Response> getPendingTransactions() async {
    return await _dio.get('/wallet/pending');
  }

  Future<Response> approveDeposit(int transactionId) async {
    return await _dio.put('/wallet/approve/$transactionId');
  }

  // ========== Booking ==========

  Future<Response> getCourts() async {
    return await _dio.get('/booking/courts');
  }

  Future<Response> getCalendar(DateTime from, DateTime to) async {
    return await _dio.get('/booking/calendar', queryParameters: {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
  }

  Future<Response> book(int courtId, DateTime startTime, DateTime endTime) async {
    return await _dio.post('/booking/book', data: {
      'courtId': courtId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    });
  }

  Future<Response> cancelBooking(int bookingId) async {
    return await _dio.post('/booking/cancel/$bookingId');
  }

  Future<Response> getMyBookings() async {
    return await _dio.get('/booking/my-bookings');
  }

  // ========== Token Management ==========

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // ========== Tournament ==========

  Future<List<Tournament>> getTournaments() async {
    try {
      final response = await _dio.get('/tournament');
      return (response.data as List).map((i) => Tournament.fromJson(i)).toList();
    } catch (e) {
      print('Get Tournaments Error: $e');
      return [];
    }
  }

  Future<TournamentDetail?> getTournamentDetail(int id) async {
    try {
      final response = await _dio.get('/tournament/$id');
      return TournamentDetail.fromJson(response.data);
    } catch (e) {
      print('Get Tournament Detail Error: $e');
      return null;
    }
  }

  Future<bool> joinTournament(int id) async {
    try {
      await _dio.post('/tournament/join/$id');
      return true;
    } on DioException catch (e) {
      print('Join Tournament Error: ${e.response?.data}');
      return false;
    }
  }

  Future<bool> createTournament(Map<String, dynamic> data) async {
    try {
      await _dio.post('/tournament', data: data);
      return true;
    } catch (e) {
      print('Create Tournament Error: $e');
      return false;
    }
  }

  Future<bool> generateSchedule(int id) async {
    try {
      await _dio.post('/tournament/generate-schedule/$id');
      return true;
    } catch (e) {
      print('Generate Schedule Error: $e');
      return false;
    }
  }

  Future<bool> updateMatchResult(int id, int score1, int score2) async {
    try {
      await _dio.put('/tournament/matches/$id/result', data: {
        'score1': score1,
        'score2': score2,
      });
      return true;
    } catch (e) {
      print('Update Match Result Error: $e');
      return false;
    }
  }
}
