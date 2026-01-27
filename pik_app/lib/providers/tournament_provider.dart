import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class TournamentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Tournament> _tournaments = [];
  List<Tournament> get tournaments => _tournaments;

  TournamentDetail? _selectedTournament;
  TournamentDetail? get selectedTournament => _selectedTournament;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadTournaments() async {
    _isLoading = true;
    notifyListeners();

    _tournaments = await _apiService.getTournaments();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTournamentDetail(int id) async {
    _isLoading = true;
    notifyListeners();

    _selectedTournament = await _apiService.getTournamentDetail(id);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> joinTournament(int id) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.joinTournament(id);
    if (success) {
      await loadTournamentDetail(id);
      await loadTournaments();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> createTournament(String name, DateTime start, DateTime end, double fee, double prize) async {
     _isLoading = true;
    notifyListeners();

    final success = await _apiService.createTournament({
      'name': name,
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'entryFee': fee,
      'prizePool': prize
    });

    if (success) {
      await loadTournaments();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> generateSchedule(int id) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.generateSchedule(id);
    if (success) {
      await loadTournamentDetail(id);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateMatchResult(int matchId, int score1, int score2) async {
    // Optimistic update handled by Notification ideally, but for now simple
    final success = await _apiService.updateMatchResult(matchId, score1, score2);
    return success;
  }

  // Handle SignalR updates
  void updateMatch(MatchModel match) {
    if (_selectedTournament != null && _selectedTournament!.id == match.tournamentId) {
      var matches = _selectedTournament!.matches;
      final index = matches.indexWhere((m) => m.id == match.id);
      if (index != -1) {
        matches[index] = match;
        // Re-create object to trigger notify if needed? Or just notify
        notifyListeners();
      }
    }
  }
}
