import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/showtime_bloc.dart';
import '../models/movie.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';
import '../services/mock_showtime_service.dart';
import '../theme/app_theme.dart';

class ShowtimePage extends StatelessWidget {
  final Movie movie;
  final Cinema cinema;

  const ShowtimePage({super.key, required this.movie, required this.cinema});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShowtimeBloc(MockShowtimeService())
        ..add(FetchShowtimes(
          cinemaId: cinema.id,
          movieId: movie.id,
          date: DateTime.now(),
        ),),
      child: _ShowtimeView(movie: movie, cinema: cinema),
    );
  }
}

class _ShowtimeView extends StatefulWidget {
  final Movie movie;
  final Cinema cinema;

  const _ShowtimeView({required this.movie, required this.cinema});

  @override
  State<_ShowtimeView> createState() => _ShowtimeViewState();
}

class _ShowtimeViewState extends State<_ShowtimeView> {
  late DateTime _selectedDate;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dates = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    context.read<ShowtimeBloc>().add(FetchShowtimes(
          cinemaId: widget.cinema.id,
          movieId: widget.movie.id,
          date: date,
        ),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
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
                  widget.movie.fullBackdropUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.movie.fullBackdropUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppTheme.cardDark),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryDark.withOpacity(0.8),
                          AppTheme.primaryDark,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Movie + Cinema info
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
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.theaters_rounded,
                                size: 16, color: AppTheme.accentCyan,),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.cinema.name,
                                style: const TextStyle(
                                  color: AppTheme.accentCyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

          // Date selector
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                itemBuilder: (context, index) => _buildDateChip(_dates[index]),
              ),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                    '場次時間',
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

          // Showtimes
          BlocBuilder<ShowtimeBloc, ShowtimeState>(
            builder: (context, state) {
              if (state is ShowtimeLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentPurple),
                  ),
                );
              }

              if (state is ShowtimeLoaded) {
                if (state.showtimes.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 48, color: AppTheme.textSecondary,),
                          SizedBox(height: 12),
                          Text(
                            '今日暫無場次',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 16,),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group by format + language
                final byFormat = <String, List<Showtime>>{};
                for (final st in state.showtimes) {
                  byFormat.putIfAbsent(st.displayLabel, () => []).add(st);
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final format = byFormat.keys.toList()[index];
                        final showtimes = byFormat[format]!;
                        return _buildFormatSection(format, showtimes);
                      },
                      childCount: byFormat.length,
                    ),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildDateChip(DateTime date) {
    final isSelected =
        _selectedDate.day == date.day && _selectedDate.month == date.month;
    final isToday =
        DateTime.now().day == date.day && DateTime.now().month == date.month;
    final dayOfWeek = DateFormat('E', 'zh_TW').format(date);
    final dayNum = date.day.toString();

    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.accentGradient : null,
          color: isSelected ? null : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? null
              : Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? '今天' : dayOfWeek,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSection(String format, List<Showtime> showtimes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getFormatColor(format).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              format,
              style: TextStyle(
                color: _getFormatColor(format),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: showtimes.map((st) => _buildShowtimeChip(st)).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildShowtimeChip(Showtime showtime) {
    final timeStr = DateFormat('HH:mm').format(showtime.time);
    final isPast = showtime.time.isBefore(DateTime.now());

    return Material(
      color: isPast ? AppTheme.cardDark.withOpacity(0.5) : AppTheme.cardDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isPast
            ? null
            : () {
                _showBookingSnackbar(showtime);
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPast
                  ? AppTheme.dividerColor.withOpacity(0.3)
                  : AppTheme.accentPurple.withOpacity(0.4),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color:
                          isPast ? AppTheme.textSecondary : AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!isPast) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.confirmation_num_rounded,
                      size: 12,
                      color: AppTheme.accentPurple.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                showtime.hallName,
                style: TextStyle(
                  color: isPast
                      ? AppTheme.textSecondary.withOpacity(0.6)
                      : AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingSnackbar(Showtime showtime) async {
    if (showtime.bookingUrl != null) {
      try {
        final uri = Uri.parse(showtime.bookingUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Error launching booking URL: $e');
      }
    }

    Get.snackbar(
      '無法開啟訂票頁面',
      '該影城暫不支援直接跳轉，請手動搜尋：${widget.cinema.name}',
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
    );
  }

  Color _getFormatColor(String format) {
    final upper = format.toUpperCase();
    if (upper.contains('IMAX')) return AppTheme.accentCyan;
    if (upper.contains('4DX') || upper.contains('MX4D')) return const Color(0xFFEF4444);
    if (upper.contains('3D')) return AppTheme.accentBlue;
    if (upper.contains('DOLBY')) return const Color(0xFF10B981);
    if (upper.contains('D-BOX') || upper.contains('DBOX')) return const Color(0xFF9333EA);

    // 語言
    if (upper.contains('國語') || upper.contains('中文')) return const Color(0xFFEC4899);
    if (upper.contains('日語')) return const Color(0xFF6366F1);
    if (upper.contains('韓語')) return const Color(0xFF0EA5E9);
    if (upper.contains('台語')) return const Color(0xFF14B8A6);

    return const Color(0xFF94A3B8);
  }
}
