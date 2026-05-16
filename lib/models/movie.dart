class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;
  final String? director;
  final List<String>? cast;
  final String? atmoviesId;
  final String? trailerUrl;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
    this.director,
    this.cast,
    this.atmoviesId,
    this.trailerUrl,
  });

  /// 取得海報完整 URL
  String get fullPosterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// 取得背景圖完整 URL
  String get fullBackdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) return '';
    if (backdropPath!.startsWith('http')) return backdropPath!;
    return 'https://image.tmdb.org/t/p/w780$backdropPath';
  }
}
