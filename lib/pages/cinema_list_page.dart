import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/cinema_bloc.dart';
import '../models/movie.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';
import '../services/atmovies_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../services/rating_service.dart';
import '../widgets/star_rating.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart';

class CinemaListPage extends StatelessWidget {
  final Movie movie;

  const CinemaListPage({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CinemaBloc(AtmoviesService())
        ..add(FetchCinemas(movie, regionCode: 'a02')),
      child: _CinemaListView(movie: movie),
    );
  }
}

class _CinemaListView extends StatefulWidget {
  final Movie movie;

  const _CinemaListView({required this.movie});

  @override
  State<_CinemaListView> createState() => _CinemaListViewState();
}

class _CinemaListViewState extends State<_CinemaListView> {
  String _selectedRegion = 'a02';
  final RatingService _ratingService = RatingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Movie header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.movie.fullPosterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.movie.fullPosterUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppTheme.cardDark),
                        )
                      : Container(color: AppTheme.cardDark),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryDark.withOpacity(0.7),
                          AppTheme.primaryDark,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (widget.movie.overview.isNotEmpty)
                          Text(
                            widget.movie.overview,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 12),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, authState) {
                            return StreamBuilder<Map<String, dynamic>>(
                              stream: _ratingService
                                  .getRatingStream(widget.movie.id),
                              builder: (context, snapshot) {
                                String? uid = authState is Authenticated
                                    ? authState.user.uid
                                    : null;
                                final data = snapshot.data;
                                final average = (data?['averageRating'] as num?)
                                        ?.toDouble() ??
                                    0.0;
                                final count =
                                    (data?['ratingCount'] as num?)?.toInt() ??
                                        0;
                                final userRating = (uid != null &&
                                        data?['users'] != null &&
                                        data!['users'][uid] != null)
                                    ? (data['users'][uid] as num).toDouble()
                                    : null;

                                return Row(
                                  children: [
                                    StarRating(
                                      rating: average,
                                      size: 16,
                                      color: AppTheme.accentPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${average.toStringAsFixed(1)} ($count)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () => _showRatingBottomSheet(
                                          context, userRating ?? 0.0),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: userRating != null
                                            ? AppTheme.accentPurple
                                                .withOpacity(0.2)
                                            : Colors.white24,
                                        foregroundColor: userRating != null
                                            ? AppTheme.accentPurple
                                            : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 0),
                                        minimumSize: const Size(60, 28),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: Text(
                                        userRating != null
                                            ? '已評 ${userRating.toStringAsFixed(1)} ★'
                                            : '我要評分',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Region selector
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: AtmoviesService.regionCodes.entries.map((entry) {
                  final isSelected = _selectedRegion == entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.key),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedRegion = entry.value);
                          context.read<CinemaBloc>().add(
                                ChangeRegion(widget.movie, entry.value),
                              );
                        }
                      },
                      selectedColor: AppTheme.accentPurple.withOpacity(0.3),
                      backgroundColor: AppTheme.cardDark,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.accentPurple
                            : AppTheme.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.accentPurple
                            : AppTheme.dividerColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '影城與場次',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cinema + showtime list
          BlocBuilder<CinemaBloc, CinemaState>(
            builder: (context, state) {
              if (state is CinemaLoading) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => _buildShimmerItem(),
                      childCount: 5,
                    ),
                  ),
                );
              }

              if (state is CinemaError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          '載入失敗',
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is CinemaLoaded) {
                final entries = state.cinemaShowtimes.entries.toList();
                if (entries.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.theaters_rounded,
                              size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            '此地區暫無場次',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = entries[index];
                        return _buildCinemaCard(entry.key, entry.value);
                      },
                      childCount: entries.length,
                    ),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCinemaCard(Cinema cinema, List<Showtime> showtimes) {
    final now = DateTime.now();
    final todayShowtimes = <Showtime>[];
    final tomorrowShowtimes = <Showtime>[];

    for (final st in showtimes) {
      if (st.time.year == now.year &&
          st.time.month == now.month &&
          st.time.day == now.day) {
        todayShowtimes.add(st);
      } else {
        tomorrowShowtimes.add(st);
      }
    }

    if (todayShowtimes.isEmpty && tomorrowShowtimes.isEmpty)
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cinema name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.theaters_rounded,
                  color: AppTheme.accentPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cinema.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (todayShowtimes.isNotEmpty)
            _buildShowtimesByFormat(todayShowtimes),

          if (tomorrowShowtimes.isNotEmpty) ...[
            Center(
              child: TextButton(
                onPressed: () =>
                    _showTomorrowDialog(context, cinema, tomorrowShowtimes),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '明(${DateFormat('MM/dd').format(tomorrowShowtimes.first.time)})場次',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_double_arrow_down_rounded,
                        size: 14),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildShowtimesByFormat(List<Showtime> showtimes) {
    if (showtimes.isEmpty) return const SizedBox.shrink();

    final byFormat = <String, List<Showtime>>{};
    for (final st in showtimes) {
      // 使用 displayLabel 分組（格式+語言），再依據廳名細分
      final baseLabel = st.displayLabel;
      final groupKey = st.hallName.isNotEmpty ? '$baseLabel ${st.hallName}' : baseLabel;
      byFormat.putIfAbsent(groupKey, () => []).add(st);
    }

    for (final format in byFormat.keys) {
      byFormat[format]!.sort((a, b) => a.time.compareTo(b.time));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byFormat.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getFormatColor(entry.key).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: _getFormatColor(entry.key),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((st) {
                  final timeStr = DateFormat('HH:mm').format(st.time);
                  final isPast = st.time.isBefore(DateTime.now());
                  return Material(
                    color: isPast
                        ? AppTheme.surfaceDark.withOpacity(0.5)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: isPast
                          ? null
                          : () async {
                              if (st.bookingUrl != null) {
                                try {
                                  final uri = Uri.parse(st.bookingUrl!);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                    return;
                                  }
                                } catch (e) {
                                  print('Error: $e');
                                }
                              }
                              Get.snackbar(
                                '無法開啟訂票頁面',
                                '請手動前往影城官網訂票',
                                backgroundColor:
                                    Colors.redAccent.withOpacity(0.9),
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                margin: const EdgeInsets.all(16),
                              );
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPast
                                ? AppTheme.dividerColor.withOpacity(0.3)
                                : AppTheme.accentPurple.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    color: isPast
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (!isPast) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.confirmation_num_rounded,
                                    size: 10,
                                    color: AppTheme.accentPurple
                                        .withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                            if (st.hallName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  st.hallName,
                                  style: TextStyle(
                                    color: isPast
                                        ? AppTheme.textSecondary.withOpacity(0.7)
                                        : _getFormatColor(st.hallName),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showTomorrowDialog(
      BuildContext context, Cinema cinema, List<Showtime> showtimes) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: AppTheme.accentPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${cinema.name} - ${DateFormat('MM/dd').format(showtimes.first.time)} 場次',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Get.back()),
                ],
              ),
              const SizedBox(height: 16),
              _buildShowtimesByFormat(showtimes),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Color _getFormatColor(String format) {
    final upper = format.toUpperCase();
    if (upper.contains('IMAX')) return AppTheme.accentCyan;
    if (upper.contains('3D')) return AppTheme.accentBlue;
    if (upper.contains('4DX') || upper.contains('MX4D'))
      return const Color(0xFFEF4444); // 體感特技紅
    if (upper.contains('SCREEN X') || upper.contains('SCREENX'))
      return const Color(0xFFF59E0B);
    if (upper.contains('DOLBY')) return const Color(0xFF10B981);
    if (upper.contains('LUXE')) return const Color(0xFF38BDF8); // 巨幕天藍
    if (upper.contains('BOOM')) return const Color(0xFFF97316); // 震動亮度橘

    // 特殊影廳
    if (upper.contains('TITAN')) return const Color(0xFFEAB308); // 黃色
    if (upper.contains('MUCROWN')) return const Color(0xFFD946EF); // 亮粉紫
    if (upper.contains('GC') || upper.contains('GOLD CLASS'))
      return const Color(0xFFF59E0B); // 琥珀色
    if (upper.contains('MAPPA')) return const Color(0xFF84CC16); // 萊姆綠
    if (upper.contains('LUVNE')) return const Color(0xFFF43F5E); // 玫瑰紅
    if (upper.contains('PRESTIGE')) return const Color(0xFFB45309); // 尊爵金棕
    if (upper.contains('D-BOX') || upper.contains('DBOX'))
      return const Color(0xFF9333EA); // 體感紫

    // 語言
    if (upper.contains('國語') || upper.contains('中文') || upper.contains('國文'))
      return const Color(0xFFEC4899); // 粉色
    if (upper.contains('日語') || upper.contains('日文'))
      return const Color(0xFF6366F1); // 靛藍色
    if (upper.contains('韓語') || upper.contains('韓文'))
      return const Color(0xFF0EA5E9); // 天藍色
    if (upper.contains('台語')) return const Color(0xFF14B8A6); // 天青綠色

    return const Color(0xFF94A3B8);
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardDark,
      highlightColor: AppTheme.surfaceDark,
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showRatingBottomSheet(BuildContext context, double initialRating) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      Get.snackbar(
        '需要登入',
        '請先登入後再替這部電影評分！',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
      Get.to(() => const LoginPage());
      return;
    }

    final user = authState.user;
    double currentRating = initialRating == 0.0 ? 5.0 : initialRating;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '給予《${widget.movie.title}》評分',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            StarRating(
              rating: currentRating,
              size: 40,
              color: AppTheme.accentPurple,
              onRatingChanged: (rating) {
                currentRating = rating;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Get.back(); // close bottom sheet
                  Get.dialog(const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false);

                  try {
                    await _ratingService.submitRating(
                      movieId: widget.movie.id,
                      uid: user.uid,
                      newRating: currentRating,
                    );
                    Get.back(); // close loading dialog
                    Get.snackbar(
                      '評分成功',
                      '謝謝您的回饋！',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppTheme.accentPurple.withOpacity(0.9),
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                    );
                  } catch (e) {
                    Get.back(); // close loading dialog
                    Get.snackbar('錯誤', '評分失敗：$e',
                        snackPosition: SnackPosition.TOP);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('確認送出',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
