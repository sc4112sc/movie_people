class Showtime {
  final String id;
  final String cinemaId;
  final int movieId;
  final DateTime time;
  final String hallName;
  final String format; // 影廳格式：2D, 3D, IMAX, 4DX, ULTRA 4DX, MX4D...
  final String language; // 語言版本：英語, 中文, 國語, 日語...（空字串=未提供）
  final String? bookingUrl; // 訂票網址（如有）

  Showtime({
    required this.id,
    required this.cinemaId,
    required this.movieId,
    required this.time,
    required this.hallName,
    required this.format,
    this.language = '',
    this.bookingUrl,
  });

  /// 取得用於分組顯示的完整標籤
  /// 例如："4DX 3D 英語"、"2D 中文"、"IMAX"
  String get displayLabel {
    final parts = <String>[];
    if (format.isNotEmpty && format != '2D') {
      parts.add(format);
    }
    if (language.isNotEmpty) {
      parts.add(language);
    }
    if (parts.isEmpty) {
      parts.add('2D');
    }
    return parts.join(' ');
  }
}
