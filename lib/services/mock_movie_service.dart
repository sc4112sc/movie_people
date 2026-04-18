import '../models/movie.dart';

class MockMovieService {
  /// 取得當前上映電影（真實台灣院線片資料）
  Future<List<Movie>> getNowPlaying({int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (page > 2) return [];
    return page == 1 ? _moviesPage1 : _moviesPage2;
  }

  static final List<Movie> _moviesPage1 = [
    Movie(
      id: 1,
      title: '功夫',
      posterPath: 'https://pics.filmaffinity.com/kung_fu-627785043-large.jpg',
      backdropPath: 'https://pics.filmaffinity.com/kung_fu-627785043-large.jpg',
      overview: '台灣賀歲強片，由柯震東主演。一段關於武術與成長的熱血故事，在農曆新年期間創下驚人票房紀錄。',
      voteAverage: 8.1,
      releaseDate: '2026-02-13',
      genreIds: [28, 35],
    ),
    Movie(
      id: 2,
      title: '雙喜',
      posterPath:
          'https://pics.filmaffinity.com/double_happiness-627785044-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/double_happiness-627785044-large.jpg',
      overview: '台灣新年檔期賣座喜劇，描述兩個家庭因一場意外而交織在一起的歡笑與感動故事。',
      voteAverage: 7.6,
      releaseDate: '2026-02-17',
      genreIds: [35, 18],
    ),
    Movie(
      id: 3,
      title: '陽光女聲合唱團',
      posterPath:
          'https://pics.filmaffinity.com/sunshine_choir-627785045-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/sunshine_choir-627785045-large.jpg',
      overview: '一群來自不同背景的女性組成合唱團，在音樂中找到力量與友誼。感人至深的台灣原創故事。',
      voteAverage: 8.0,
      releaseDate: '2026-02-28',
      genreIds: [18, 10402],
    ),
    Movie(
      id: 4,
      title: '科學新娘！',
      posterPath: 'https://pics.filmaffinity.com/the_bride-627785046-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/the_bride-627785046-large.jpg',
      overview: '靈感來自1935年《科學怪人的新娘》，改編自瑪麗·雪萊的小說。由潔西·乙乙克利和克里斯乞丁·貝爾主演的科幻驚悚電影。',
      voteAverage: 7.2,
      releaseDate: '2026-03-04',
      genreIds: [878, 27],
    ),
    Movie(
      id: 5,
      title: '劇場版 我內心的糟糕念頭',
      posterPath: 'https://pics.filmaffinity.com/boku_yaba-627785047-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/boku_yaba-627785047-large.jpg',
      overview: '改編自人氣漫畫，陰沉的男高中生市川京太郎與班上最受歡迎的女同學山田杏奈之間甜蜜又令人心跳加速的青春戀愛物語。',
      voteAverage: 8.4,
      releaseDate: '2026-02-13',
      genreIds: [16, 10749],
    ),
    Movie(
      id: 6,
      title: '忌念日：極權元年',
      posterPath:
          'https://pics.filmaffinity.com/anniversary-627785048-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/anniversary-627785048-large.jpg',
      overview: '在一個極權統治的年代，一群勇敢的年輕人試圖在禁忌的紀念日揭露被掩蓋的歷史真相。驚悚懸疑之作。',
      voteAverage: 6.8,
      releaseDate: '2026-03-06',
      genreIds: [53, 27],
    ),
    Movie(
      id: 7,
      title: '穿越吧！不思議少女',
      posterPath:
          'https://pics.filmaffinity.com/wonder_girl-627785049-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/wonder_girl-627785049-large.jpg',
      overview: '一位平凡少女意外穿越到奇幻世界，展開了一場充滿冒險與驚喜的旅程。適合闔家觀賞的奇幻電影。',
      voteAverage: 7.0,
      releaseDate: '2026-03-06',
      genreIds: [14, 12],
    ),
    Movie(
      id: 8,
      title: '鬼娃娃',
      posterPath:
          'https://pics.filmaffinity.com/ghost_doll-627785050-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/ghost_doll-627785050-large.jpg',
      overview: '一個看似可愛的娃娃背後藏著令人毛骨悚然的秘密。泰國恐怖片，在台灣引發熱烈討論。',
      voteAverage: 6.5,
      releaseDate: '2026-03-06',
      genreIds: [27],
    ),
  ];

  static final List<Movie> _moviesPage2 = [
    Movie(
      id: 9,
      title: '極限返航',
      posterPath: 'https://pics.filmaffinity.com/hail_mary-627785051-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/hail_mary-627785051-large.jpg',
      overview: '改編自《絕地救援》作者安迪·乙爾同名暢銷科幻小說，萊恩·葛斯林飾演科學老師獨自前往太空，解開太陽衰亡的謎團。',
      voteAverage: 8.3,
      releaseDate: '2026-03-18',
      genreIds: [878, 12],
    ),
    Movie(
      id: 10,
      title: '深度安靜',
      posterPath:
          'https://pics.filmaffinity.com/deep_quiet-627785052-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/deep_quiet-627785052-large.jpg',
      overview: '金馬最佳短片導演沈可尚首部劇情長片，由張孝全、林依晨和金士傑主演。探討人心深處最幽暗的秘密。',
      voteAverage: 7.5,
      releaseDate: '2026-03-20',
      genreIds: [18, 53],
    ),
    Movie(
      id: 11,
      title: '怪奇比莉：溫柔重擊巡迴演唱會3D電影',
      posterPath:
          'https://pics.filmaffinity.com/billie_eilish-627785053-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/billie_eilish-627785053-large.jpg',
      overview: '怪奇比莉全球售罄巡迴演唱會精華紀錄。以震撼的3D方式呈現她的舞台魅力與音樂才華。',
      voteAverage: 7.8,
      releaseDate: '2026-03-19',
      genreIds: [99, 10402],
    ),
    Movie(
      id: 12,
      title: '百日紅',
      posterPath:
          'https://pics.filmaffinity.com/miss_hokusai-627785054-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/miss_hokusai-627785054-large.jpg',
      overview: '經典動畫電影重映。描述日本浮世繪大師葛飾北齋之女阿榮的故事，在江戶時代以畫筆開創屬於自己的藝術之路。',
      voteAverage: 7.3,
      releaseDate: '2026-03-19',
      genreIds: [16, 18, 36],
    ),
    Movie(
      id: 13,
      title: '這不只是個間諜故事',
      posterPath: 'https://pics.filmaffinity.com/spy_story-627785055-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/spy_story-627785055-large.jpg',
      overview: '一部融合動作與幽默的間諜電影。主角被捲入國際陰謀，卻發現事情遠比想像中複雜得多。',
      voteAverage: 6.9,
      releaseDate: '2026-03-06',
      genreIds: [28, 53, 35],
    ),
    Movie(
      id: 14,
      title: '世外',
      posterPath:
          'https://pics.filmaffinity.com/another_world-627785056-large.jpg',
      backdropPath:
          'https://pics.filmaffinity.com/another_world-627785056-large.jpg',
      overview: '一部探索人與自然關係的台灣電影。在遠離塵囂的山林中，主角重新發現生命的意義。',
      voteAverage: 7.4,
      releaseDate: '2026-03-13',
      genreIds: [18],
    ),
  ];
}
