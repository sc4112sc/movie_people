import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../bloc/movie_bloc.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'cinema_list_page.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  final int index;

  const MovieDetailPage({super.key, required this.movie, required this.index});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  @override
  void initState() {
    super.initState();
    // 進入頁面時觸發加載詳細資訊
    context.read<MovieBloc>().add(LoadMovieDetail(widget.index, widget.movie));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<MovieBloc, MovieState>(
        builder: (context, state) {
          // 取得最新的 movie 資料
          Movie currentMovie = widget.movie;
          if (state is MovieLoaded) {
            if (widget.index < state.movies.length &&
                state.movies[widget.index].id == widget.movie.id) {
              currentMovie = state.movies[widget.index];
              print(
                  'DEBUG: Movie detail updated from state: ${currentMovie.title}, length: ${currentMovie.overview.length}');
            } else {
              print(
                  'DEBUG: ID mismatch! widget.id=${widget.movie.id}, state.id=${state.movies[widget.index].id}');
            }
          }

          return Stack(
            children: [
              // 全局背景漸層
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.surfaceDark,
                      AppTheme.primaryDark,
                    ],
                    stops: [0.0, 0.5],
                  ),
                ),
              ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(currentMovie),
                  SliverToBoxAdapter(
                    child: _buildMovieInfo(currentMovie),
                  ),
                  const SliverToBoxAdapter(
                    // 留出底部按鈕的空間，確保演員列表不會被遮住
                    child: SizedBox(height: 200),
                  ),
                ],
              ),
              // 返回按鈕 (自訂在左上角，不受 SliverAppBar 滾動影響)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 底部固定按鈕
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(currentMovie),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Movie movie) {
    // 優先使用 backdrop，沒有的話用 poster
    final imageUrl = movie.fullBackdropUrl.isNotEmpty
        ? movie.fullBackdropUrl
        : movie.fullPosterUrl;

    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.45,
      pinned: false,
      stretch: true,
      automaticallyImplyLeading: false, // 我們已經自訂返回按鈕了
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: AppTheme.cardDark,
                      highlightColor: AppTheme.surfaceDark,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.cardDark,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 50, color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                : Container(color: AppTheme.cardDark),
            // 漸層遮罩，讓下方的文字更容易閱讀
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    AppTheme.primaryDark,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieInfo(Movie movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // 標題
          Text(
            movie.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.2,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          // 標籤列 (評分、日期)
          Row(
            children: [
              if (movie.voteAverage > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.theaters_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '全台 ${movie.voteAverage.toInt()} 廳',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (movie.releaseDate.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppTheme.textSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '上映: ${movie.releaseDate}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          // 劇情簡介標題
          const Text(
            '劇情簡介',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // 劇情內容
          if (movie.director == null && movie.cast == null && (movie.overview.isEmpty || movie.overview.startsWith('片長：')))
            _buildShimmerText(4)
          else
            Text(
              (movie.overview.isEmpty || movie.overview.startsWith('片長：'))
                  ? '暫無劇情簡介。'
                  : movie.overview,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),

          if (movie.director != null || (movie.director == null && movie.cast == null)) ...[
            const SizedBox(height: 32),
            const Text(
              '導演',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (movie.director == null)
              _buildShimmerBlock(width: 120, height: 24)
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentPurple.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  movie.director!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],

          if (movie.cast != null || (movie.director == null && movie.cast == null)) ...[
            const SizedBox(height: 32),
            const Text(
              '演員',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (movie.cast == null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(5, (index) => _buildShimmerBlock(width: 80 + (index % 3 * 20), height: 30)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: movie.cast!
                    .map((actor) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            actor,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(Movie movie) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: ElevatedButton(
            onPressed: () {
              Get.to(
                () => CinemaListPage(movie: movie),
                transition: Transition.cupertino,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 8,
              shadowColor: AppTheme.accentPurple.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.theaters_rounded),
                SizedBox(width: 8),
                Text(
                  '查看時刻表',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerText(int lines) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceDark,
      highlightColor: AppTheme.cardDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lines,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 14,
            width: index == lines - 1 ? 200 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBlock({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceDark,
      highlightColor: AppTheme.cardDark,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}
