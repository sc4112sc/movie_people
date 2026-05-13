import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/movie.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';

class AtmoviesService {
  static const String _baseUrl = 'https://www.atmovies.com.tw';

  /// 地區代碼對照
  static const Map<String, String> regionCodes = {
    '基隆': 'a01',
    '台北/新北': 'a02',
    '桃園': 'a03',
    '新竹': 'a35',
    '苗栗': 'a37',
    '台中': 'a04',
    '彰化': 'a47',
    '南投': 'a49',
    '雲林': 'a45',
    '嘉義': 'a05',
    '台南': 'a06',
    '高雄': 'a07',
    '屏東': 'a87',
    '宜蘭/花蓮/台東': 'a08',
    '澎湖/金門': 'a09',
  };

  /// 影城訂票網址映射
  static const Map<String, String> _cinemaBookingUrls = {
    '威秀': 'https://www.vscinemas.com.tw/',
    '秀泰': 'https://www.showtimes.com.tw/',
    '國賓': 'https://www.ambassador.com.tw/',
    '美麗華': 'https://www.miramarcinemas.tw/',
    '喜樂時代': 'https://www.centuryasia.com.tw/',
    '新光': 'https://www.skcinemas.com/',
    '樂聲': 'https://www.luxcinema.com.tw/',
    'IN89': 'https://www.in89cinemax.com/',
    '真善美': 'https://wonderful.movie.com.tw/',
    '誠品': 'https://arthouse.eslite.com/',
    '哈拉': 'http://www.halarcity.com/',
    '百老匯': 'https://www.broadway-cineplex.com.tw/',
    '威尼斯': 'https://www.venice-cinema.com.tw/',
    'SBC': 'https://www.sbc-cinemas.com.tw/',
    '中影': 'https://movie.movie.com.tw/',
    '鴻金寶': 'https://www.hjbc.com.tw/',
    '民和': 'https://www.minhe-cinema.com.tw/',
    '環球': 'https://www.u-cinemas.com.tw/',
    '日新': 'https://www.city-cinema.com.tw/',
    '華威': 'https://www.woviecinemas.com.tw/',
    '嘉年華': 'https://www.carnival-cinema.com.tw/',
    '總督': 'https://governor.tixi.com.tw/',
    '喜滿客': 'https://www.cinemark.com.tw/',
    '美麗新': 'https://www.miranacinemas.com/',
    '親親': 'https://chinchin.tixi.com.tw/',
    '萬代福': 'http://www.wonderful-cinemas.com.tw/',
    '白宮': 'https://whitehouse.tixi.com.tw/',
    '斗六': 'https://douliu.tixi.com.tw/',
    '虎尾': 'https://huwei.tixi.com.tw/',
    '佳聯': 'https://jialian.tixi.com.tw/',
    '南台': 'https://nan-tai.tixi.com.tw/',
    '梅花': 'https://blossom.movie.com.tw/',
    '光點': 'https://www.spot.org.tw/',
  };

  /// 根據影城名稱取得訂票網址
  static String? getBookingUrl(String cinemaName) {
    final name = cinemaName.toUpperCase();
    for (final entry in _cinemaBookingUrls.entries) {
      if (name.contains(entry.key.toUpperCase())) {
        return entry.value;
      }
    }
    // 預設 fallback 到 EZ訂
    return 'https://www.ezding.com.tw/';
  }

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

      // 從 og:description 或一般 description 取得簡介
      String overview = movie.overview;
      final metaDesc =
          document.querySelector('meta[property="og:description"]') ??
              document.querySelector('meta[name="description"]');
      if (metaDesc != null) {
        String desc = metaDesc.attributes['content']?.trim() ?? '';

        // 過濾掉 ATMovies 預設的無效簡介
        if (desc.contains('提供最新的電影資訊、預告片、劇照')) {
          desc = '';
        }

        if (desc.isNotEmpty) {
          overview = desc;
        }
      }

      // 如果 meta tag 取不到，或者還是預設值，試著從內文直接抓取
      if (overview.isEmpty || overview.startsWith('片長：')) {
        // 嘗試多種選擇器
        final selectors = [
          '#filmTagBlock span:nth-of-type(2)',
          '#filmTagBlock span',
          '#filmTagBlock p',
          '#filmTagBlock',
        ];

        for (final selector in selectors) {
          final element = document.querySelector(selector);
          if (element != null) {
            String text = element.text.trim();
            // 過濾掉一些不需要的文字
            if (text.isNotEmpty &&
                !text.startsWith('片長：') &&
                !text.contains('提供最新的電影資訊')) {
              overview = text;
              break;
            }
          }
        }
      }

      // 解析導演與演員
      String? director;
      List<String> castList = [];

      final castDataItems =
          document.querySelectorAll('#filmCastDataBlock ul li');
      bool collectingCast = false;

      for (final item in castDataItems) {
        final text = item.text.trim();
        if (text.startsWith('導演：')) {
          director = text.replaceFirst('導演：', '').trim();
          collectingCast = false;
        } else if (text.startsWith('演員：')) {
          final castStr = text.replaceFirst('演員：', '').trim();
          if (castStr.isNotEmpty) {
            castList.addAll(
                castStr.split(RegExp(r'[,\s、/]+')).where((s) => s.isNotEmpty));
          }
          collectingCast = true;
        } else if (collectingCast) {
          // 如果遇到其他標籤，停止收集演員
          if (text.contains('：') || text.contains('IMDb')) {
            collectingCast = false;
            continue;
          }
          if (text.isNotEmpty && text != 'more') {
            castList.add(text);
          }
        }
      }
      List<String>? cast = castList.isNotEmpty ? castList : null;

      // 優先使用內部構建的正確海報 URL (通常是最穩定的)
      String posterUrl = movie.atmoviesId != null
          ? _getPosterUrl(movie.atmoviesId!)
          : (movie.posterPath ?? '');

      // 嘗試從頁面中獲取更準確的海報 (例如大型海報)
      final ogImage = document.querySelector('meta[property="og:image"]');
      if (ogImage != null) {
        final imgUrl = ogImage.attributes['content'] ?? '';
        // 排除目前已失效的 photowant.com 網址
        if (imgUrl.isNotEmpty && !imgUrl.contains('photowant.com')) {
          posterUrl = imgUrl.startsWith('http') ? imgUrl : '$_baseUrl$imgUrl';
        }
      }

      // 如果還是沒抓到，或者抓到的是失效網址，嘗試從頁面中的 .Poster img 抓取高品質海報
      if (posterUrl.isEmpty || posterUrl.contains('broken') || posterUrl.contains('photowant.com')) {
        final posterImg = document.querySelector('.Poster img, .filmPoster img');
        if (posterImg != null) {
          final src = posterImg.attributes['src'] ?? '';
          if (src.isNotEmpty && !src.contains('photowant.com')) {
            posterUrl = src.startsWith('http') ? src : '$_baseUrl$src';
          }
        }
      }
      
      // 最後保險：如果還是 photowant，則強制使用我們建構的 pl_ 路徑
      if (posterUrl.contains('photowant.com') && movie.atmoviesId != null) {
        posterUrl = _getPosterUrl(movie.atmoviesId!);
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
        director: director,
        cast: cast,
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
    final allLis = document.querySelectorAll('ul.theaterListPA li, ul li');

    Cinema? currentCinema;
    String currentFormat = '2D';
    String currentLanguage = '';
    List<Showtime> currentShowtimes = [];
    bool inShowtimeSection = false;
    bool didParseTimeSinceLastFormatChange = false;

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
          final uniqueKey = '${cinemaCode}_$cinemaName';
          if (cinemaName.isEmpty || processedCinemas.contains(uniqueKey))
            continue;
          processedCinemas.add(uniqueKey);

          currentCinema = Cinema(
            id: cinemaCode,
            name: cinemaName,
            address: '',
            district: '',
            city: cityName,
          );
          currentShowtimes = [];
          currentFormat = '2D';
          currentLanguage = '';
          inShowtimeSection = true;
          didParseTimeSinceLastFormatChange = false;
          continue;
        }
      }

      if (!inShowtimeSection || currentCinema == null) continue;

      final text = li.text.trim();
      final cssClass = li.attributes['class'] ?? '';

      // 先驗證是否為時間格式，以防將時間字串（如 14:20 GC廰) 誤判為格式標籤
      final timePattern = RegExp(r'(\d{1,2})：(\d{2})(.*)');
      final timeMatch = timePattern.firstMatch(text);

      if (timeMatch != null) {
        final hour = int.parse(timeMatch.group(1)!);
        final minute = int.parse(timeMatch.group(2)!);

        String hallName = '';
        if (timeMatch.groupCount >= 3) {
          hallName = timeMatch.group(3)!.trim();
          hallName = hallName.replaceAll(RegExp(r'^[\(（]|[\)）]$'), '').trim();
        }

        final now = DateTime.now();
        var showDate = DateTime(now.year, now.month, now.day, hour, minute);

        if (hour >= 0 && hour < 6 && now.hour >= 6) {
          showDate = showDate.add(const Duration(days: 1));
        }

        currentShowtimes.add(Showtime(
          id: '${currentCinema.id}_${movie.id}_${hour}_$minute',
          cinemaId: currentCinema.id,
          movieId: movie.id,
          time: showDate,
          hallName: hallName,
          format: currentFormat,
          language: currentLanguage,
          bookingUrl: getBookingUrl(currentCinema.name),
        ));

        // 成功解析到時間，標記為已解析
        didParseTimeSinceLastFormatChange = true;
        continue;
      } else if (text.isNotEmpty) {
        // 如果不是時間，則判斷是否為版本/語言標籤
        bool isVersionHeader = cssClass.contains('filmVersion');
        if (!isVersionHeader) {
          final upper = text.toUpperCase();
          if (upper.contains('IMAX') ||
              upper.contains('4DX') ||
              upper.contains('MX4D') ||
              upper.contains('SCREEN X') ||
              upper.contains('SCREENX') ||
              upper.contains('3D') ||
              upper.contains('DOLBY') ||
              upper.contains('LUXE') ||
              upper.contains('BOOM') ||
              upper.contains('D-BOX') ||
              upper.contains('DBOX') ||
              upper.contains('TITAN') ||
              upper.contains('GC') ||
              upper.contains('GOLD CLASS') ||
              upper.contains('MUCROWN') ||
              upper.contains('MAPPA') ||
              upper.contains('LUVNE') ||
              upper.contains('PRESTIGE') ||
              text.contains('數位') ||
              text.contains('語') ||
              text.contains('英文') ||
              text.contains('國文') ||
              text.contains('中文') ||
              text.contains('日文') ||
              text.contains('韓文')) {
            isVersionHeader = true;
          }
        }

        if (isVersionHeader) {
          final cleaned = text.replaceAll('版', '').trim();
          final parsed = _parseFilmVersion(cleaned);

          if (didParseTimeSinceLastFormatChange) {
            // 遇到新的格式區塊（上一個區塊已解析完時間），完全重設
            currentFormat = parsed.format;
            currentLanguage = parsed.language;
            didParseTimeSinceLastFormatChange = false;
          } else {
            // 連續多個 filmVersion 行堆疊（還沒解析到時間），合併
            if (parsed.format != '2D') {
              if (currentFormat == '2D') {
                currentFormat = parsed.format;
              } else if (!currentFormat.contains(parsed.format)) {
                currentFormat = '$currentFormat ${parsed.format}'.trim();
              }
            }
            if (parsed.language.isNotEmpty) {
              currentLanguage = parsed.language;
            }
          }
        }
      }
    }

    // 儲存最後一個影城
    if (currentCinema != null && currentShowtimes.isNotEmpty) {
      result[currentCinema] = currentShowtimes;
    }

    return result;
  }

  /// 從 filmVersion 文字中解構出 format（影廳格式）和 language（語言版本）
  ///
  /// 範例：
  /// - "英文" → format: "2D", language: "英語"
  /// - "中文" → format: "2D", language: "中文"
  /// - "國語" → format: "2D", language: "國語"
  /// - "4DX" → format: "4DX", language: ""
  /// - "ULTRA 4DX" → format: "ULTRA 4DX", language: ""
  /// - "3D英語" → format: "3D", language: "英語"
  /// - "英語3D" → format: "3D", language: "英語"
  /// - "IMAX" → format: "IMAX", language: ""
  static _ParsedVersion _parseFilmVersion(String text) {
    String format = '2D';
    String language = '';

    final upper = text.toUpperCase();

    // 1. 先提取格式關鍵字（從長到短匹配，避免 "4DX" 先被 "3D" 搶走）
    final formatPatterns = [
      'ULTRA 4DX',
      'IMAX 3D',
      'IMAX',
      'MX4D',
      '4DX',
      'SCREEN X',
      'SCREENX',
      'DOLBY ATMOS',
      'DOLBY',
      'D-BOX',
      'DBOX',
      'LUXE',
      'BOOM',
      '3D',
    ];

    String remaining = text;
    final foundFormats = <String>[];

    for (final pattern in formatPatterns) {
      if (upper.contains(pattern)) {
        foundFormats.add(pattern);
        // 從 remaining 中移除已匹配的格式文字（不區分大小寫）
        remaining = remaining
            .replaceAll(
                RegExp(RegExp.escape(pattern), caseSensitive: false), '')
            .trim();
      }
    }

    if (foundFormats.isNotEmpty) {
      format = foundFormats.join(' ');
    }

    // 2. 從剩餘文字中提取語言
    // 統一語言名稱：英文/英語 → 英語, 中文 → 中文, 國語 → 國語, 國文 → 國語
    final langMap = {
      '英語': '英語',
      '英文': '英語',
      '國語': '國語',
      '國文': '國語',
      '中文': '中文',
      '日語': '日語',
      '日文': '日語',
      '韓語': '韓語',
      '韓文': '韓語',
      '台語': '台語',
    };

    for (final entry in langMap.entries) {
      if (remaining.contains(entry.key) || text.contains(entry.key)) {
        language = entry.value;
        break;
      }
    }

    return _ParsedVersion(format: format, language: language);
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

class _ParsedVersion {
  final String format;
  final String language;

  _ParsedVersion({required this.format, required this.language});
}
