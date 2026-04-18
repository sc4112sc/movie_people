class Showtime {
  final String id;
  final String cinemaId;
  final int movieId;
  final DateTime time;
  final String hallName;
  final String format; // 2D, 3D, IMAX

  Showtime({
    required this.id,
    required this.cinemaId,
    required this.movieId,
    required this.time,
    required this.hallName,
    required this.format,
  });
}
