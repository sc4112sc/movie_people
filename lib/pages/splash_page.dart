import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/movie_bloc.dart';
import '../services/atmovies_service.dart';
import '../theme/app_theme.dart';
import 'movie_list_page.dart';
import '../services/location_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _bgScale;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _particleOpacity;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    // Background animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bgScale = Tween<double>(begin: 1.15, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOutCubic),
    );

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Text animations
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _particleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Pulse animation for logo ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // 在動畫期間並行請求定位權限
    final locationService = LocationService();
    await locationService.requestPermission();

    await Future.delayed(const Duration(milliseconds: 1200));
    _navigateToHome();
  }

  void _navigateToHome() {
    if (!mounted) return;
    
    // 觸發首次抓取資料
    context.read<MovieBloc>().add(FetchNowPlaying());
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MovieListPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _logoController,
          _textController,
          _particleController,
          _pulseController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Animated gradient background
              Transform.scale(
                scale: _bgScale.value,
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.2),
                      radius: 1.2,
                      colors: [
                        Color(0xFF1A1040),
                        Color(0xFF0D1117),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating particles
              ...List.generate(12, (i) => _buildParticle(i, size)),

              // Glow orbs
              _buildGlowOrb(
                const Alignment(-0.6, -0.5),
                AppTheme.accentPurple.withOpacity(0.18),
                200,
              ),
              _buildGlowOrb(
                const Alignment(0.7, 0.3),
                AppTheme.accentBlue.withOpacity(0.15),
                180,
              ),
              _buildGlowOrb(
                const Alignment(0.0, 0.6),
                AppTheme.accentCyan.withOpacity(0.10),
                150,
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with pulse ring
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            Transform.scale(
                              scale: _pulseScale.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.accentPurple.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            // Middle ring
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.accentPurple.withOpacity(0.15),
                                    AppTheme.accentBlue.withOpacity(0.15),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppTheme.accentPurple.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                            // Inner logo circle
                            Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.accentGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentPurple.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: AppTheme.accentBlue.withOpacity(0.3),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '映',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App title
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleOpacity,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.accentGradient.createShader(bounds),
                          child: const Text(
                            '電影人',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    SlideTransition(
                      position: _subtitleSlide,
                      child: FadeTransition(
                        opacity: _subtitleOpacity,
                        child: const Text(
                          '台灣電影時刻表',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom loading indicator
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _subtitleOpacity,
                  child: Column(
                    children: [
                      _buildLoadingDots(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlowOrb(AlignmentGeometry alignment, Color color, double size) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  Widget _buildParticle(int index, Size size) {
    final random = math.Random(index * 42 + 7);
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final particleSize = random.nextDouble() * 3 + 1;
    final animOffset = random.nextDouble();

    final anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Interval(
          animOffset * 0.5,
          (animOffset * 0.5 + 0.5).clamp(0, 1),
          curve: Curves.easeInOut,
        ),
      ),
    );

    final colors = [
      AppTheme.accentPurple,
      AppTheme.accentBlue,
      AppTheme.accentCyan,
    ];
    final color = colors[index % colors.length];

    return Positioned(
      left: x,
      top: y - (anim.value * 20),
      child: FadeTransition(
        opacity: _particleOpacity,
        child: Opacity(
          opacity: (math.sin(anim.value * math.pi)).clamp(0.0, 1.0) * 0.7,
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final progress = (_particleController.value + i * 0.33) % 1.0;
            final scale = 0.6 + 0.4 * math.sin(progress * math.pi);
            final opacity = 0.3 + 0.7 * math.sin(progress * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.accentGradient,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
