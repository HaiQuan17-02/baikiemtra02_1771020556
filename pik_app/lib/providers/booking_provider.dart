import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Court> _courts = [];
  List<CourtCalendar> _calendar = [];
  List<Booking> _myBookings = [];
  bool _isLoading = false;
  String? _error;

  List<Court> get courts => _courts;
  List<CourtCalendar> get calendar => _calendar;
  List<Booking> get myBookings => _myBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCourts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getCourts();
      _courts = (response.data as List)
          .map((e) => Court.fromJson(e))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Lỗi tải danh sách sân';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCalendar(DateTime from, DateTime to) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getCalendar(from, to);
      _calendar = (response.data as List)
          .map((e) => CourtCalendar.fromJson(e))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Lỗi tải lịch đặt sân';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> book(int courtId, DateTime startTime, DateTime endTime) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.book(courtId, startTime, endTime);
      await loadMyBookings();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi đặt sân: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      await _apiService.cancelBooking(bookingId);
      await loadMyBookings();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lỗi hủy đặt sân';
      return false;
    }
  }

  Future<void> loadMyBookings() async {
    try {
      final response = await _apiService.getMyBookings();
      _myBookings = (response.data as List)
          .map((e) => Booking.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = 'Lỗi tải lịch đã đặt';
    }
  }

  List<BookingSlot> getBookingsForCourt(int courtId) {
    final courtCal = _calendar.firstWhere(
      (c) => c.courtId == courtId,
      orElse: () => CourtCalendar(courtId: courtId, courtName: '', bookings: []),
    );
    return courtCal.bookings;
  }

  bool isSlotAvailable(int courtId, DateTime start, DateTime end) {
    final bookings = getBookingsForCourt(courtId);
    for (var booking in bookings) {
      if (booking.status != 'Cancelled') {
        if ((start.isBefore(booking.endTime) && end.isAfter(booking.startTime))) {
          return false;
        }
      }
    }
    return true;
  }
}
