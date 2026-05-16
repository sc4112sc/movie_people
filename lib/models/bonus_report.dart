class BonusReport {
  final String id;
  final String movieId;
  final String cinemaName;
  final bool isAvailable;
  final DateTime timestamp;
  final String? userId;
  final String? userEmail;
  final String? userPhotoUrl;

  BonusReport({
    required this.id,
    required this.movieId,
    required this.cinemaName,
    required this.isAvailable,
    required this.timestamp,
    this.userId,
    this.userEmail,
    this.userPhotoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'cinemaName': cinemaName,
      'isAvailable': isAvailable,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
    };
  }

  factory BonusReport.fromJson(Map<dynamic, dynamic> json) {
    return BonusReport(
      id: json['id'] as String,
      movieId: json['movieId'] as String,
      cinemaName: json['cinemaName'] as String,
      isAvailable: json['isAvailable'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String?,
      userEmail: json['userEmail'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
    );
  }
}
