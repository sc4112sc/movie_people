import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../bloc/movie_bloc.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import '../services/reminder_service.dart';

class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage({super.key});

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage> {
  late PageController _pageController;
  double _currentPage = 0.0;
  final ReminderService _reminderService = ReminderService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.72)
      ..addListener(() {
        if (_pageController.hasClients) {
          setState(() {
            _currentPage = _pageController.page!;
          });
        }
      });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieBloc>().add(FetchComingSoon());
    });
  }

  void _onPageChanged(int index, List<Movie> comingSoon) {
    for (int i = index; i <= index + 2; i++) {
      if (i < comingSoon.length) {
        final movie = comingSoon[i];
        if (movie.overview.isEmpty) {
          context.read<MovieBloc>().add(LoadMovieDetail(
            i, 
            movie, 
            isComingSoon: true,
          ),);
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchTrailer(String? url) async {
    if (url == null || url.isEmpty) {
      Get.snackbar(
        '抱歉',
        '此電影暫無預告片連結',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('錯誤', '無法開啟連結');
    }
  }

  void _showFullOverview(BuildContext context, Movie movie) {
    Get.bottomSheet(
      BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryDark.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${movie.title} - 劇情簡介',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    movie.overview,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.6,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('關閉', style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.2,
            colors: [
              AppTheme.surfaceDark.withOpacity(0.5),
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: BlocBuilder<MovieBloc, MovieState>(
                  builder: (context, state) {
                    if (state is MovieLoading) {
                      return _buildShimmerLoading();
                    }

                    if (state is MovieLoaded) {
                      if (state.comingSoon.isEmpty) {
                        return _buildEmptyOrError(state, message: '目前沒有即將上映的電影資料');
                      }
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _onPageChanged(0, state.comingSoon);
                      });

                      return PageView.builder(
                        controller: _pageController,
                        itemCount: state.comingSoon.length,
                        onPageChanged: (index) => _onPageChanged(index, state.comingSoon),
                        itemBuilder: (context, index) {
                          return _buildMovieCard(state.comingSoon[index], index);
                        },
                      );
                    }

                    if (state is MovieError) {
                      return _buildEmptyOrError(state, message: state.message);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '即將上映',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Movie movie, int index) {
    double relativePosition = index - _currentPage;
    double scale = 1.0 - (relativePosition.abs() * 0.2).clamp(0.0, 0.2);
    double opacity = 1.0 - (relativePosition.abs() * 0.6).clamp(0.0, 0.8);
    
    final bool isReminded = _reminderService.isReminded(movie.atmoviesId ?? movie.id.toString());

    return Center(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: AspectRatio(
            aspectRatio: 0.5,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: movie.fullPosterUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.cardDark),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.cardDark,
                        child: const Icon(Icons.movie, color: Colors.white24, size: 50),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${movie.releaseDate} 上映',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            movie.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          if (movie.overview.isNotEmpty)
                            GestureDetector(
                              onTap: () => _showFullOverview(context, movie),
                              child: Text(
                                movie.overview,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchTrailer(movie.trailerUrl),
                                  icon: const Icon(Icons.play_circle_fill_rounded),
                                  label: const Text('觀看預告'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: isReminded 
                                      ? AppTheme.accentPurple.withOpacity(0.3) 
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isReminded ? AppTheme.accentPurple : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final status = await _reminderService.toggleReminder(movie);
                                    if (mounted) {
                                      setState(() {});
                                      
                                      String title = '';
                                      String message = '';
                                      Color bgColor = Colors.black87;

                                      switch (status) {
                                        case ReminderStatus.scheduled:
                                          title = '提醒已設定';
                                          message = '將在上映當天早上 9:00 提醒您！';
                                          bgColor = AppTheme.accentPurple.withOpacity(0.8);
                                          break;
                                        case ReminderStatus.cancelled:
                                          title = '提醒已取消';
                                          message = '已從提醒清單中移除';
                                          break;
                                        case ReminderStatus.failed:
                                          title = '設定失敗';
                                          message = '請稍後再試或檢查通知權限';
                                          bgColor = Colors.red.withOpacity(0.8);
                                          break;
                                      }

                                      Get.snackbar(
                                        title,
                                        message,
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: bgColor,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 2),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    isReminded ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, 
                                    color: isReminded ? AppTheme.accentPurple : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardDark,
      highlightColor: AppTheme.surfaceDark,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.72),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const SizedBox(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrError(MovieState state, {String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter_rounded, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 20),
            Text(
              message ?? '尚無即將上映資料', 
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<MovieBloc>().add(FetchComingSoon()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新整理'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
