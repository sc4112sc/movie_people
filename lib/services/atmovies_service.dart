import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/movie.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';

class AtmoviesService {
  static const String _baseUrl = 'https://www.atmovies.com.tw';

  /// 地區代碼對照
  static const Map<String, String> regionCodes = {
    '台北': 'a02',
    '桃園': 'a03',
    '新竹': 'a35',
    '台中': 'a04',
    '嘉義': 'a05',
    '台南': 'a06',
    '高雄': 'a07',
    '基隆': 'a01',
    '苗栗': 'a37',
    '彰化': 'a47',
    '雲林': 'a45',
    '南投': 'a49',
    '屏東': 'a87',
    '宜蘭': 'a39',
    '花蓮': 'a38',
    '台東': 'a89',
  };

  /// 取得當前上映電影列表
  Future<List<Movie>> getNowPlaying() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movie/now/'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final document = html_parser.parse(response.body);
    final movies = <Movie>[];

    // 正確的選擇器：ul.filmListPA li
    final movieItems = document.querySelectorAll('ul.filmListPA li');

    for (final item in movieItems) {
      final link = item.querySelector('a[href*="/movie/f"]');
      if (link == null) continue;

      final href = link.attributes['href'] ?? '';
      final match = RegExp(r'/movie/(f[a-z0-9]+)/').firstMatch(href);
      if (match == null) continue;

      final movieId = match.group(1)!;
      final title = link.text.trim();
      if (title.isEmpty) continue;

      // 從 span.runtime 取得日期和片長
      final runtime = item.querySelector('span.runtime');
      String releaseDate = '';
      String duration = '';
      int theaterCount = 0;
      if (runtime != null) {
        final text = runtime.text;
        final dateMatch = RegExp(r'(\d{4}/\d{1,2}/\d{1,2})').firstMatch(text);
        if (dateMatch != null) {
          releaseDate = dateMatch.group(1)!.replaceAll('/', '-');
        }
        final durMatch = RegExp(r'\((\d+)分\)').firstMatch(text);
        if (durMatch != null) {
          duration = durMatch.group(1)!;
        }
        final theaterMatch = RegExp(r'\((\d+)廳\)').firstMatch(text);
        if (theaterMatch != null) {
          theaterCount = int.parse(theaterMatch.group(1)!);
        }
      }

      final posterUrl = _getPosterUrl(movieId);

      movies.add(Movie(
        id: movieId.hashCode,
        title: title,
        posterPath: posterUrl,
        backdropPath: posterUrl,
        overview: duration.isNotEmpty ? '片長：$duration 分鐘' : '',
        voteAverage: theaterCount.toDouble(),
        releaseDate: releaseDate,
        genreIds: [],
        atmoviesId: movieId,
      ));
    }

    // 依照上映廳數排序 (越多越熱門) -> 相同則依照名稱排
    movies.sort((a, b) {
      final cmp = b.voteAverage.compareTo(a.voteAverage);
      if (cmp != 0) return cmp;
      return a.title.compareTo(b.title);
    });

    return movies;
  }

  /// 取得電影詳細資訊（簡介）
  Future<Movie> getMovieDetail(Movie movie) async {
    if (movie.atmoviesId == null) return movie;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/${movie.atmoviesId}/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
        },
      );

      if (response.statusCode != 200) return movie;

      final document = html_parser.parse(response.body);

      // 從 og:description 取得簡介
      String overview = movie.overview;
      final metaDesc =
          document.querySelector('meta[property="og:description"]');
      if (metaDesc != null) {
        final desc = metaDesc.attributes['content'] ?? '';
        if (desc.isNotEmpty && desc.length > 10) {
          overview = desc;
        }
      }

      // 從 og:image 取得海報
      String posterUrl = movie.posterPath ?? '';
      final ogImage = document.querySelector('meta[property="og:image"]');
      if (ogImage != null) {
        final imgUrl = ogImage.attributes['content'] ?? '';
        if (imgUrl.isNotEmpty) {
          posterUrl = imgUrl.startsWith('http') ? imgUrl : '$_baseUrl$imgUrl';
        }
      }

      return Movie(
        id: movie.id,
        title: movie.title,
        posterPath: posterUrl,
        backdropPath: posterUrl,
        overview: overview,
        voteAverage: movie.voteAverage,
        releaseDate: movie.releaseDate,
        genreIds: movie.genreIds,
        atmoviesId: movie.atmoviesId,
      );
    } catch (e) {
      return movie;
    }
  }

  /// 取得指定電影在指定地區的影城與時刻表
  Future<Map<Cinema, List<Showtime>>> getShowtimes({
    required Movie movie,
    required String regionCode,
  }) async {
    if (movie.atmoviesId == null) return {};

    final response = await http.get(
      Uri.parse('$_baseUrl/showtime/${movie.atmoviesId}/$regionCode/'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
      },
    );

    if (response.statusCode != 200) return {};

    final document = html_parser.parse(response.body);
    final result = <Cinema, List<Showtime>>{};

    final cityName = regionCodes.entries
        .firstWhere((e) => e.value == regionCode,
            orElse: () => const MapEntry('', ''))
        .key;

    final processedCinemas = <String>{};

    Cinema? currentCinema;
    List<Showtime> currentShowtimes = [];
    String currentFormat = '2D';

    // 遍歷所有 <li> 元素找出影城和時間
    final allLis = document.querySelectorAll('ul.theaterListPA li, ul li');
    bool inShowtimeSection = false;

    for (final li in allLis) {
      // 檢查是否包含影城連結
      final cinemaLink = li.querySelector('a[href*="/showtime/t"]');
      if (cinemaLink != null) {
        final href = cinemaLink.attributes['href'] ?? '';
        final cinemaMatch = RegExp(r'/showtime/(t[0-9a-z]+)/').firstMatch(href);
        if (cinemaMatch != null) {
          // 儲存前一個影城
          if (currentCinema != null && currentShowtimes.isNotEmpty) {
            result[currentCinema] = List.from(currentShowtimes);
          }

          final cinemaCode = cinemaMatch.group(1)!;
          final cinemaName = cinemaLink.text.trim();
          if (cinemaName.isEmpty || processedCinemas.contains(cinemaCode))
            continue;
          processedCinemas.add(cinemaCode);

          currentCinema = Cinema(
            id: cinemaCode,
            name: cinemaName,
            address: '',
            district: '',
            city: cityName,
          );
          currentShowtimes = [];
          currentFormat = '2D';
          inShowtimeSection = true;
          continue;
        }
      }

      if (!inShowtimeSection || currentCinema == null) continue;

      final text = li.text.trim();

      // 版本標記
      if (text.contains('IMAX') ||
          text.contains('4DX') ||
          text.contains('SCREEN X') ||
          text.contains('3D版') ||
          text.contains('Dolby')) {
        currentFormat = text.replaceAll('版', '').trim();
        continue;
      }

      // 解析時間（格式: HH：MM）
      final timePattern = RegExp(r'^(\d{1,2})：(\d{2})$');
      final timeMatch = timePattern.firstMatch(text);
      if (timeMatch != null) {
        final hour = int.parse(timeMatch.group(1)!);
        final minute = int.parse(timeMatch.group(2)!);
        final now = DateTime.now();
        currentShowtimes.add(Showtime(
          id: '${currentCinema.id}_${movie.id}_${hour}_$minute',
          cinemaId: currentCinema.id,
          movieId: movie.id,
          time: DateTime(now.year, now.month, now.day, hour, minute),
          hallName: '',
          format: currentFormat,
        ));
      }
    }

    // 儲存最後一個影城
    if (currentCinema != null && currentShowtimes.isNotEmpty) {
      result[currentCinema] = currentShowtimes;
    }

    return result;
  }

  /// 構建海報 URL
  static String _getPosterUrl(String movieId) {
    return 'https://www.atmovies.com.tw/photo101/$movieId/pl_$movieId.jpg';
  }

  /// 取得所有地區名稱
  static List<String> getRegions() {
    return regionCodes.keys.toList();
  }
}
