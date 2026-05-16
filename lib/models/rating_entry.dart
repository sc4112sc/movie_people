class RatingEntry {
  final String id;
  final String movieId;
  final String uid;
  final double rating;
  final DateTime timestamp;
  final String? displayName;
  final String? userEmail;
  final String? userPhotoUrl;

  RatingEntry({
    required this.id,
    required this.movieId,
    required this.uid,
    required this.rating,
    required this.timestamp,
    this.displayName,
    this.userEmail,
    this.userPhotoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'uid': uid,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
      'displayName': displayName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
    };
  }

  factory RatingEntry.fromJson(String id, Map<dynamic, dynamic> json) {
    return RatingEntry(
      id: id,
      movieId: json['movieId'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      displayName: json['displayName'] as String?,
      userEmail: json['userEmail'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
    );
  }
}
