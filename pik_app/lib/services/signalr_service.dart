import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

class SignalRService {
  // static const String hubUrl = 'http://10.0.2.2:5054/hubs/pcm'; // Android emulator
  static const String hubUrl = 'http://localhost:5054/hubs/pcm'; // Windows/iOS

  HubConnection? _hubConnection;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Callbacks
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function()? onCalendarUpdated;
  Function(MatchModel)? onMatchUpdated;
  Function(int)? onTournamentUpdated;
  Function(Map<String, dynamic>)? onMatchScoreUpdated;

  Future<void> connect() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async => token,
        ))
        .withAutomaticReconnect()
        .build();

    // Listen for notifications
    _hubConnection?.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        // Backend now expects to send an object { message, type } or just message string?
        // If getting type mismatch error before, let's enable dynamic handling
        final arg = arguments[0];
        if (arg is Map<String, dynamic>) {
          onNotificationReceived?.call(arg);
        } else if (arg is String) {
          onNotificationReceived?.call({'message': arg, 'type': 'General'});
        }
      }
    });

    // Listen for calendar updates
    _hubConnection?.on('UpdateCalendar', (arguments) {
        onCalendarUpdated?.call();
    });

    // Listen for match score updates
    _hubConnection?.on('UpdateMatchScore', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        onMatchScoreUpdated?.call(data);
      }
    });

    try {
      await _hubConnection?.start();
      debugPrint('SignalR Connected');
    } catch (e) {
      debugPrint('SignalR Connection Error: $e');
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }

  Future<void> joinMatchGroup(int matchId) async {
    await _hubConnection?.invoke('JoinMatchGroup', args: [matchId]);
  }

  Future<void> leaveMatchGroup(int matchId) async {
    await _hubConnection?.invoke('LeaveMatchGroup', args: [matchId]);
  }

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
}
