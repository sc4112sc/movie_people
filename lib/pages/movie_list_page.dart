import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import '../bloc/movie_bloc.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

import '../bloc/auth_bloc.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'movie_detail_page.dart';
class MovieListPage extends StatelessWidget {
  const MovieListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.accentPurple,
        backgroundColor: AppTheme.cardDark,
        onRefresh: () async {
          final completer = Completer<void>();
          context.read<MovieBloc>().add(FetchNowPlaying(completer: completer));
          return completer.future;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: 100,
              actions: [
                _buildProfileButton(context),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '現正上映',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<MovieBloc, MovieState>(
              builder: (context, state) {
                if (state is MovieLoading) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.55,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildShimmerCard(),
                        childCount: 6,
                      ),
                    ),
                  );
                }

                if (state is MovieError) {
                  return SliverFillRemaining(
                    child: _buildErrorWidget(context, state.message),
                  );
                }

                if (state is MovieLoaded) {
                  if (state.movies.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyWidget(context),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.48,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildMovieCard(state.movies[index], index),
                        childCount: state.movies.length,
                      ),
                    ),
                  );
                }

                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(Movie movie, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          Get.to(
            () => MovieDetailPage(movie: movie, index: index),
            transition: Transition.cupertino,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 海報圖片 (2:3 比例)
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      movie.fullPosterUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: movie.fullPosterUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppTheme.cardDark,
                                child: const Center(
                                  child: Icon(Icons.movie_rounded,
                                      size: 36, color: AppTheme.textSecondary,),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppTheme.cardDark,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.movie_rounded,
                                          size: 36,
                                          color: AppTheme.textSecondary,),
                                      const SizedBox(height: 8),
                                      Text(
                                        movie.title,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: AppTheme.cardDark,
                              child: const Center(
                                child: Icon(Icons.movie_rounded,
                                    size: 36, color: AppTheme.textSecondary,),
                              ),
                            ),
                      // 底部漸層
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 底部標籤 (日期 + 廳數)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Row(
                          children: [
                            if (movie.releaseDate.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3,),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  movie.releaseDate,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (movie.voteAverage > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3,),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.theaters_rounded,
                                        color: Colors.white, size: 10,),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${movie.voteAverage.toInt()}廳',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 標題
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text(
                movie.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 片長
            if (movie.overview.isNotEmpty)
              Text(
                movie.overview,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardDark,
      highlightColor: AppTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 100,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
                size: 48,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '目前沒有上映中的電影',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '請稍後下拉重新整理再試試看',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<MovieBloc>().add(FetchNowPlaying());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新整理'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    // 過濾系統錯誤訊息，給使用者更友善的提示
    String userMessage = '無法取得遠端資料，請檢查您的網路連線。';
    if (message.contains('HTTP')) {
      userMessage = '伺服器目前無回應，請稍後再試。';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppTheme.accentPurple,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '網路連線中斷',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userMessage,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<MovieBloc>().add(FetchNowPlaying());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新連線'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showProfileBottomSheet(context, user),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.surfaceDark,
                backgroundImage: user.photoURL != null
                    ? CachedNetworkImageProvider(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
          );
        }

        // Unauthenticated
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 30, color: Colors.white),
            onPressed: () {
              Get.to(() => const LoginPage(), transition: Transition.downToUp);
            },
          ),
        );
      },
    );
  }

  void _showProfileBottomSheet(BuildContext context, User user) {
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
            CircleAvatar(
              radius: 40,
              backgroundImage: user.photoURL != null
                  ? CachedNetworkImageProvider(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? '電影人',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // close bottom sheet
                  context.read<AuthBloc>().add(SignOutRequested());
                  Get.snackbar(
                    '登出成功',
                    '您已成功登出電影人，期待您再次回來！',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: AppTheme.cardDark.withOpacity(0.95),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                    icon: const Icon(Icons.check_circle_outline, color: AppTheme.accentPurple),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '登出',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
