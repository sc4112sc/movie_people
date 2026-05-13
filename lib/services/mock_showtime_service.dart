 import '../models/cinema.dart';
 import '../models/showtime.dart';
import 'atmovies_service.dart';

class MockShowtimeService {
  static final List<Cinema> _cinemas = [
    // 台北
    Cinema(
        id: 'c1',
        name: '信義威秀影城',
        address: '台北市信義區松壽路20號',
        district: '信義區',
        city: '台北'),
    Cinema(
        id: 'c2',
        name: '京站威秀影城',
        address: '台北市大同區承德路一段1號',
        district: '大同區',
        city: '台北'),
    Cinema(
        id: 'c3',
        name: '台北國賓影城',
        address: '台北市中山區長春路176號',
        district: '中山區',
        city: '台北'),
    Cinema(
        id: 'c4',
        name: '美麗華大直影城',
        address: '台北市中山區敬業三路22號',
        district: '中山區',
        city: '台北'),
    Cinema(
        id: 'c5',
        name: '喜樂時代影城 南港店',
        address: '台北市南港區忠孝東路七段369號',
        district: '南港區',
        city: '台北'),
    // 新北
    Cinema(
        id: 'c6',
        name: '板橋秀泰影城',
        address: '新北市板橋區中山路一段152號',
        district: '板橋區',
        city: '新北'),
    Cinema(
        id: 'c7',
        name: '林口三井 OUTLET 威秀影城',
        address: '新北市林口區文化三路一段356號',
        district: '林口區',
        city: '新北'),
    // 桃園
    Cinema(
        id: 'c8',
        name: '桃園統領威秀影城',
        address: '桃園市桃園區中正路61號',
        district: '桃園區',
        city: '桃園'),
    Cinema(
        id: 'c9',
        name: '中壢 SBC 星橋國際影城',
        address: '桃園市中壢區中園路二段501號',
        district: '中壢區',
        city: '桃園'),
    // 台中
    Cinema(
        id: 'c10',
        name: '台中站前秀泰影城',
        address: '台中市東區南京路66號',
        district: '東區',
        city: '台中'),
    Cinema(
        id: 'c11',
        name: '台中大遠百威秀影城',
        address: '台中市西屯區台灣大道三段251號',
        district: '西屯區',
        city: '台中'),
    Cinema(
        id: 'c12',
        name: '台中國賓影城',
        address: '台中市南屯區文心南五路一段331號',
        district: '南屯區',
        city: '台中'),
    // 高雄
    Cinema(
        id: 'c13',
        name: '高雄大遠百威秀影城',
        address: '高雄市苓雅區三多四路21號',
        district: '苓雅區',
        city: '高雄'),
    Cinema(
        id: 'c14',
        name: '高雄喜滿客影城',
        address: '高雄市前鎮區中華五路789號',
        district: '前鎮區',
        city: '高雄'),
    Cinema(
        id: 'c15',
        name: '高雄 MLD 影城',
        address: '高雄市鼓山區蓬萊路115號',
        district: '鼓山區',
        city: '高雄'),
  ];

  static final List<String> _formats = ['2D', '3D', 'IMAX', 'IMAX 3D', '4DX'];
  static final List<String> _languages = ['英語', '中文', '國語', '日語', ''];
  static final List<String> _halls = [
    '1廳',
    '2廳',
    '3廳',
    '4廳',
    '5廳',
    '6廳',
    'IMAX廳',
    '巨幕廳',
    'Gold Class廳'
  ];

  /// 取得播放特定電影的影城列表
  List<Cinema> getCinemasForMovie(int movieId) {
    // 模擬：根據 movieId 返回部分影城
    final seed = movieId % 5;
    final count = 8 + (movieId % 5);
    final cinemas = <Cinema>[];
    for (int i = 0; i < count && i < _cinemas.length; i++) {
      cinemas.add(_cinemas[(i + seed) % _cinemas.length]);
    }
    return cinemas;
  }

  /// 取得特定影城特定電影的時刻表
  List<Showtime> getShowtimes({
    required String cinemaId,
    required int movieId,
    required DateTime date,
  }) {
    // 模擬時刻表資料
    final showtimes = <Showtime>[];
    final baseHour = 10 + (movieId % 3);

    final timesCount = 4 + (movieId + cinemaId.hashCode) % 4;

    for (int i = 0; i < timesCount; i++) {
      final hour = baseHour + (i * 3) % 14;
      if (hour >= 24) continue;
      final minute = (i % 3) * 20;
      final formatIndex = (i + movieId) % 3; // mostly 2D with some 3D/IMAX

      showtimes.add(Showtime(
        id: '${cinemaId}_${movieId}_${date.day}_$i',
        cinemaId: cinemaId,
        movieId: movieId,
        time: DateTime(date.year, date.month, date.day, hour, minute),
        hallName: _halls[(i + movieId) % _halls.length],
        format: formatIndex < 2 ? _formats[0] : _formats[formatIndex],
        language: _languages[(i + movieId) % _languages.length],
        bookingUrl: AtmoviesService.getBookingUrl(_cinemas.firstWhere((c) => c.id == cinemaId).name),
      ));
    }

    showtimes.sort((a, b) => a.time.compareTo(b.time));
    return showtimes;
  }

  /// 取得所有城市
  List<String> getCities() {
    return _cinemas.map((c) => c.city).toSet().toList();
  }
}
