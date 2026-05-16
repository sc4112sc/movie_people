class BonusReport {
  final String id;
  final String movieId;
  final String cinemaName;
  final String format; // Added format field
  final bool isAvailable;
  final DateTime timestamp;
  final String? userId;
  final String? userEmail;
  final String? userPhotoUrl;
  final String? displayName;

  BonusReport({
    required this.id,
    required this.movieId,
    required this.cinemaName,
    required this.format,
    required this.isAvailable,
    required this.timestamp,
    this.userId,
    this.userEmail,
    this.userPhotoUrl,
    this.displayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'cinemaName': cinemaName,
      'format': format,
      'isAvailable': isAvailable,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'displayName': displayName,
    };
  }

  factory BonusReport.fromJson(Map<dynamic, dynamic> json) {
    return BonusReport(
      id: json['id'] as String? ?? '',
      movieId: json['movieId'] as String? ?? '',
      cinemaName: json['cinemaName'] as String? ?? '',
      format: json['format'] as String? ?? '數位',
      isAvailable: json['isAvailable'] as bool? ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String) 
          : DateTime.now(),
      userId: json['userId'] as String?,
      userEmail: json['userEmail'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      displayName: json['displayName'] as String?,
    );
  }
}
