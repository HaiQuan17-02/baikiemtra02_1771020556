class UserInfo {
  final String userId;
  final String email;
  final String fullName;
  final int? memberId;
  final double walletBalance;
  final String tier;
  final List<String> roles;

  UserInfo({
    required this.userId,
    required this.email,
    required this.fullName,
    this.memberId,
    required this.walletBalance,
    required this.tier,
    required this.roles,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      memberId: json['memberId'],
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      tier: json['tier'] ?? 'Standard',
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  bool get isAdmin => roles.contains('Admin') || roles.contains('Treasurer');
}

class AuthResponse {
  final bool success;
  final String? token;
  final DateTime? expiresAt;
  final String? message;
  final UserInfo? user;

  AuthResponse({
    required this.success,
    this.token,
    this.expiresAt,
    this.message,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      token: json['token'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      message: json['message'],
      user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
    );
  }
}

class WalletTransaction {
  final int id;
  final int memberId;
  final double amount;
  final String type;
  final String status;
  final String? description;
  final DateTime createdDate;

  WalletTransaction({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    required this.createdDate,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      memberId: json['memberId'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      description: json['description'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}

class Court {
  final int id;
  final String name;
  final double pricePerHour;
  final String? description;

  Court({
    required this.id,
    required this.name,
    required this.pricePerHour,
    this.description,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'],
      name: json['name'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}

class BookingSlot {
  final int bookingId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final bool isOwner;

  BookingSlot({
    required this.bookingId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isOwner,
  });

  factory BookingSlot.fromJson(Map<String, dynamic> json) {
    return BookingSlot(
      bookingId: json['bookingId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? '',
      isOwner: json['isOwner'] ?? false,
    );
  }
}

class CourtCalendar {
  final int courtId;
  final String courtName;
  final List<BookingSlot> bookings;

  CourtCalendar({
    required this.courtId,
    required this.courtName,
    required this.bookings,
  });

  factory CourtCalendar.fromJson(Map<String, dynamic> json) {
    return CourtCalendar(
      courtId: json['courtId'],
      courtName: json['courtName'] ?? '',
      bookings: (json['bookings'] as List<dynamic>?)
              ?.map((e) => BookingSlot.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Booking {
  final int id;
  final int courtId;
  final String courtName;
  final int memberId;
  final String memberName;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;

  Booking({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.memberId,
    required this.memberName,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      courtId: json['courtId'],
      courtName: json['courtName'] ?? '',
      memberId: json['memberId'],
      memberName: json['memberName'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class WalletBalance {
  final int memberId;
  final String memberName;
  final double balance;
  final String tier;

  WalletBalance({
    required this.memberId,
    required this.memberName,
    required this.balance,
    required this.tier,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      memberId: json['memberId'],
      memberName: json['memberName'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      tier: json['tier'] ?? 'Standard',
    );
  }
}

class Tournament {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double entryFee;
  final double prizePool;
  final String status;
  final int participantCount;

  Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    required this.participantCount,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      entryFee: (json['entryFee'] as num).toDouble(),
      prizePool: (json['prizePool'] as num).toDouble(),
      status: json['status'],
      participantCount: json['participantCount'],
    );
  }
}

class TournamentDetail extends Tournament {
  final List<Participant> participants;
  final List<MatchModel> matches;

  TournamentDetail({
    required super.id,
    required super.name,
    required super.startDate,
    required super.endDate,
    required super.entryFee,
    required super.prizePool,
    required super.status,
    required super.participantCount,
    required this.participants,
    required this.matches,
  });

  factory TournamentDetail.fromJson(Map<String, dynamic> json) {
    return TournamentDetail(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      entryFee: (json['entryFee'] as num).toDouble(),
      prizePool: (json['prizePool'] as num).toDouble(),
      status: json['status'],
      participantCount: json['participantCount'],
      participants: (json['participants'] as List).map((i) => Participant.fromJson(i)).toList(),
      matches: (json['matches'] as List).map((i) => MatchModel.fromJson(i)).toList(),
    );
  }
}

class Participant {
  final int memberId;
  final String memberName;
  final DateTime joinedDate;

  Participant({required this.memberId, required this.memberName, required this.joinedDate});

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      memberId: json['memberId'],
      memberName: json['memberName'],
      joinedDate: DateTime.parse(json['joinedDate']),
    );
  }
}

class MatchModel {
  final int id;
  final int tournamentId;
  final String roundName;
  final int? team1Id;
  final String? team1Name;
  final int? team2Id;
  final String? team2Name;
  final int score1;
  final int score2;
  final String winner;
  final String status;

  MatchModel({
    required this.id,
    required this.tournamentId,
    required this.roundName,
    this.team1Id,
    this.team1Name,
    this.team2Id,
    this.team2Name,
    required this.score1,
    required this.score2,
    required this.winner,
    required this.status,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      tournamentId: json['tournamentId'],
      roundName: json['roundName'],
      team1Id: json['team1_Id'],
      team1Name: json['team1_Name'],
      team2Id: json['team2_Id'],
      team2Name: json['team2_Name'],
      score1: json['score1'],
      score2: json['score2'],
      winner: json['winner'],
      status: json['status'],
    );
  }
}
