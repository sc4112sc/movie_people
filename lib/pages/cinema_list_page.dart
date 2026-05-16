import 'dart:async';
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
import '../models/rating_entry.dart';
import '../services/atmovies_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../services/rating_service.dart';
import '../widgets/star_rating.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart';
import '../services/location_service.dart';
import '../services/bonus_service.dart';
import '../models/bonus_report.dart';

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
  final LocationService _locationService = LocationService();
  final BonusService _bonusService = BonusService();
  bool _isLocating = false;
  Map<String, BonusReport> _bonusSummary = {};
  StreamSubscription? _bonusSubscription;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initBonusStream();
  }

  @override
  void dispose() {
    _bonusSubscription?.cancel();
    super.dispose();
  }

  void _initBonusStream() {
    _bonusSubscription?.cancel();
    _bonusSubscription = _bonusService
        .getMovieBonusSummary(widget.movie.id.toString())
        .listen((summary) {
      if (mounted) {
        setState(() => _bonusSummary = summary);
      }
    });
  }

  Future<void> _initLocation() async {
    setState(() => _isLocating = true);

    final city = await _locationService.getCurrentCity();
    if (city != null) {
      final regionCode = LocationService.mapCityToRegionCode(
          city, AtmoviesService.regionCodes);
      if (regionCode != null && regionCode != _selectedRegion) {
        if (mounted) {
          setState(() {
            _selectedRegion = regionCode;
            _isLocating = false;
          });
          context
              .read<CinemaBloc>()
              .add(FetchCinemas(widget.movie, regionCode: regionCode));
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _isLocating = false);
    }
  }

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
                                final userRatingValue = (uid != null &&
                                        data?['users'] != null)
                                    ? data!['users'][uid]
                                    : null;
                                
                                double? userRating;
                                if (userRatingValue != null) {
                                  if (userRatingValue is num) {
                                    userRating = userRatingValue.toDouble();
                                  } else if (userRatingValue is Map) {
                                    userRating = (userRatingValue['rating'] as num?)?.toDouble();
                                  }
                                }

                                return Row(
                                  children: [
                                    StarRating(
                                      rating: average,
                                      size: 16,
                                      color: AppTheme.accentPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: count > 0
                                          ? () => _showRatingHistorySheet()
                                          : null,
                                      child: Row(
                                        children: [
                                          Text(
                                            '${average.toStringAsFixed(1)} ($count)',
                                            style: TextStyle(
                                              color: count > 0
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              decoration: count > 0
                                                  ? TextDecoration.underline
                                                  : null,
                                              decorationColor: Colors.white54,
                                            ),
                                          ),
                                          if (count > 0) ...[
                                            const SizedBox(width: 3),
                                            const Icon(
                                              Icons.history_rounded,
                                              size: 12,
                                              color: Colors.white54,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () => _showRatingBottomSheet(
                                          context, userRating ?? 0.0, authState),
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

          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: [
                  if (_isLocating)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentPurple,
                          ),
                        ),
                        label: Text('定位中...'),
                        backgroundColor: AppTheme.cardDark,
                        labelStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        side: BorderSide(color: AppTheme.dividerColor),
                      ),
                    ),
                  ...AtmoviesService.regionCodes.entries.map((entry) {
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
                ],
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
                        const Text(
                          '載入失敗',
                          style: TextStyle(
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

                final bonusSummary = _bonusSummary;

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = entries[index];
                        return _buildCinemaCard(entry.key, entry.value,
                            bonusSummary[entry.key.name]);
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

  Widget _buildCinemaCard(
      Cinema cinema, List<Showtime> showtimes, BonusReport? lastReport) {
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
          // Cinema name & Bonus Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cinema.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildBonusStatus(lastReport, cinema.name),
                  ],
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
      final groupKey =
          st.hallName.isNotEmpty ? '$baseLabel ${st.hallName}' : baseLabel;
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
                                    color:
                                        AppTheme.accentPurple.withOpacity(0.7),
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
                                        ? AppTheme.textSecondary
                                            .withOpacity(0.7)
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

  void _showRatingBottomSheet(BuildContext context, double initialRating, AuthState authState) {
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
    final TextEditingController commentController = TextEditingController();

    Get.bottomSheet(
      isScrollControlled: true,
      GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                TextField(
                  controller: commentController,
                  maxLength: 10,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '留下十字評語...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.accentPurple, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                          comment: commentController.text.trim(),
                          displayName: user.displayName,
                          userEmail: user.email,
                          userPhotoUrl: user.photoURL,
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
        ),
      ),
    );
  }

  void _showRatingHistorySheet() {
    Get.bottomSheet(
      _PaginatedHistorySheet<RatingEntry>(
        title: '《${widget.movie.title}》評分紀錄',
        emptyText: '尚無評分紀錄',
        loader: (lastKey) => _ratingService.getRatingHistory(
          widget.movie.id,
          lastKey: lastKey,
        ),
        itemBuilder: (entry) => _buildRatingHistoryItem(entry),
        keyExtractor: (entry) => entry.id,
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildRatingHistoryItem(RatingEntry entry) {
    final displayName = entry.displayName != null
        ? entry.displayName!
        : (entry.userEmail != null ? _maskEmail(entry.userEmail!) : '電影人');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.accentPurple.withOpacity(0.1),
            backgroundImage: entry.userPhotoUrl != null
                ? CachedNetworkImageProvider(entry.userPhotoUrl!)
                : null,
            child: entry.userPhotoUrl == null
                ? const Icon(Icons.person, size: 18, color: AppTheme.accentPurple)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.comment != null && entry.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.comment!,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatRelativeTime(entry.timestamp),
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          StarRating(
            rating: entry.rating,
            size: 13,
            color: AppTheme.accentPurple,
          ),
          const SizedBox(width: 6),
          Text(
            entry.rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppTheme.accentPurple,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showBonusHistorySheet(String cinemaName) {
    Get.bottomSheet(
      _PaginatedHistorySheet<BonusReport>(
        title: '$cinemaName 特典回報紀錄',
        emptyText: '尚無回報紀錄',
        loader: (lastTimestamp) => _bonusService.getBonusHistory(
          widget.movie.id.toString(),
          cinemaName,
          lastTimestamp: lastTimestamp,
        ),
        itemBuilder: (report) => _buildBonusHistoryItem(report),
        keyExtractor: (report) => report.timestamp.toIso8601String(),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildBonusHistoryItem(BonusReport report) {
    final isAvailable = report.isAvailable;
    final statusColor = isAvailable ? Colors.green : Colors.red;
    final displayName = report.userEmail != null
        ? _maskEmail(report.userEmail!)
        : '電影人';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withOpacity(0.1),
            backgroundImage: report.userPhotoUrl != null
                ? CachedNetworkImageProvider(report.userPhotoUrl!)
                : null,
            child: report.userPhotoUrl == null
                ? Icon(Icons.person, size: 18, color: statusColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAvailable ? '還有特典' : '已無特典',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  report.displayName ?? (report.userEmail != null ? _maskEmail(report.userEmail!) : '電影人'),
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatRelativeTime(report.timestamp),
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusStatus(BonusReport? lastReport, String cinemaName) {
    if (lastReport == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBonusReportDialog(cinemaName),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 14, color: AppTheme.accentPurple.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  '回報特典狀態',
                  style: TextStyle(
                    color: AppTheme.accentPurple.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAvailable = lastReport.isAvailable;
    final timeStr = _formatRelativeTime(lastReport.timestamp);
    final statusColor = isAvailable ? Colors.green : Colors.red;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBonusReportDialog(cinemaName),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 14,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isAvailable ? '目前有特典' : '目前已無特典',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 10,
                color: statusColor.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              if (lastReport.userPhotoUrl != null) ...[
                CircleAvatar(
                  radius: 7,
                  backgroundImage: CachedNetworkImageProvider(lastReport.userPhotoUrl!),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                timeStr,
                style: TextStyle(
                  color: statusColor.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: statusColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    return '${diff.inDays} 天前';
  }

  void _showBonusReportDialog(String cinemaName) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      Get.snackbar(
        '需要登入',
        '請先登入後再回報特典狀態！',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.accentPurple.withOpacity(0.9),
        colorText: Colors.white,
      );
      Get.to(() => const LoginPage());
      return;
    }

    final bool isAuthenticated = true; // Already checked above
    final String? currentUserEmail = authState.user.email;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false, // 讓內容貼近底部，但背景色維持
          child: Container(
            constraints: BoxConstraints(maxHeight: Get.height * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                '回報特典狀態',
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cinemaName,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 14),
                              ),
                              if (isAuthenticated && currentUserEmail != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundImage: (authState as Authenticated).user.photoURL != null
                                          ? CachedNetworkImageProvider(authState.user.photoURL!)
                                          : null,
                                      child: authState.user.photoURL == null
                                          ? const Icon(Icons.person, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '將以 ${authState.user.displayName ?? _maskEmail(currentUserEmail)} 身份回報',
                                      style: TextStyle(
                                          color: AppTheme.accentPurple.withOpacity(0.6),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Recent Reports Section
                        Row(
                          children: [
                            const Text(
                              '近期回報紀錄',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Divider(color: AppTheme.dividerColor.withOpacity(0.5))),
                            TextButton.icon(
                              onPressed: () {
                                Get.back();
                                _showBonusHistorySheet(cinemaName);
                              },
                              icon: const Icon(Icons.history_rounded, size: 14),
                              label: const Text('查看全部', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.accentPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<BonusReport>>(
                          stream: _bonusService.getReports(widget.movie.id.toString(), cinemaName),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text('目前尚無近期紀錄', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.3), fontSize: 12)),
                                ),
                              );
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: snapshot.data!.take(3).map((report) {
                                final isAvailable = report.isAvailable;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        backgroundImage: report.userPhotoUrl != null ? CachedNetworkImageProvider(report.userPhotoUrl!) : null,
                                        child: report.userPhotoUrl == null ? Icon(Icons.person, size: 16, color: isAvailable ? Colors.green : Colors.red) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                                                  size: 12,
                                                  color: isAvailable ? Colors.green : Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isAvailable ? '還有特典' : '已無特典',
                                                  style: TextStyle(
                                                    color: isAvailable ? Colors.green : Colors.red,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  _formatRelativeTime(report.timestamp),
                                                  style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              report.displayName ?? (report.userEmail != null ? _maskEmail(report.userEmail!) : '電影人'),
                                              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.4), fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildReportButton(
                        title: '還有特典',
                        subtitle: '現場仍有存貨',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                        onTap: () => _submitReport(cinemaName, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildReportButton(
                        title: '已無特典',
                        subtitle: '現場已發送完畢',
                        icon: Icons.cancel_rounded,
                        color: Colors.red,
                        onTap: () => _submitReport(cinemaName, false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildReportButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String cinemaName, bool isAvailable) async {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    String? userEmail;
    String? userPhotoUrl;
    String? displayName;

    if (authState is Authenticated) {
      userId = authState.user.uid;
      userEmail = authState.user.email;
      userPhotoUrl = authState.user.photoURL;
      displayName = authState.user.displayName;

      // 如果 Firebase 的 photoURL 為空，嘗試從 providerData 中找出 Facebook 頭像
      if (userPhotoUrl == null || userPhotoUrl!.isEmpty) {
        for (final provider in authState.user.providerData) {
          if (provider.providerId == 'facebook.com' && provider.photoURL != null) {
            userPhotoUrl = provider.photoURL;
            break;
          }
        }
      }

      // 如果是 Facebook 圖片，強制要求大圖
      if (userPhotoUrl != null && userPhotoUrl!.contains('facebook.com')) {
        if (!userPhotoUrl!.contains('type=large')) {
          userPhotoUrl = userPhotoUrl!.contains('?')
              ? '$userPhotoUrl&type=large'
              : '$userPhotoUrl?type=large';
        }
      }
    }

    final report = BonusReport(
      id: '', // Will be set by Firebase
      movieId: widget.movie.id.toString(),
      cinemaName: cinemaName,
      isAvailable: isAvailable,
      timestamp: DateTime.now(),
      userId: userId,
      userEmail: userEmail,
      userPhotoUrl: userPhotoUrl,
      displayName: displayName,
    );

    try {
      await _bonusService.submitReport(report);
      Get.back();
      Get.snackbar(
        '回報成功',
        '感謝您的分享，讓大家能掌握即時資訊！',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar('回報失敗', '發生錯誤，請稍後再試', backgroundColor: Colors.red);
    }
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    if (parts[0].length <= 2) return '***@${parts[1]}';
    return '${parts[0].substring(0, 2)}***@${parts[1]}';
  }
}

/// 通用分頁歷史紀錄底部彈窗
class _PaginatedHistorySheet<T> extends StatefulWidget {
  final String title;
  final String emptyText;
  final Future<List<T>> Function(String? lastKey) loader;
  final Widget Function(T item) itemBuilder;
  final String Function(T item) keyExtractor;

  const _PaginatedHistorySheet({
    required this.title,
    required this.emptyText,
    required this.loader,
    required this.itemBuilder,
    required this.keyExtractor,
  });

  @override
  State<_PaginatedHistorySheet<T>> createState() =>
      _PaginatedHistorySheetState<T>();
}

class _PaginatedHistorySheetState<T>
    extends State<_PaginatedHistorySheet<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final lastKey = _items.isNotEmpty
          ? widget.keyExtractor(_items.last)
          : null;
      final newItems = await widget.loader(lastKey);
      setState(() {
        _items.addAll(newItems);
        _hasMore = newItems.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.dividerColor.withOpacity(0.4), height: 1),
          // Content
          Expanded(
            child: _items.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      widget.emptyText,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.accentPurple),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: TextButton.icon(
                                    onPressed: _loadMore,
                                    icon: const Icon(Icons.expand_more_rounded,
                                        size: 18),
                                    label: const Text('載入更多'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.accentPurple,
                                    ),
                                  ),
                                ),
                        );
                      }
                      return widget.itemBuilder(_items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
