import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../bloc/auth_bloc.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 追蹤當前是哪種登入方式正在執行，避免兩顆按鈕同時轉圈
  String? _loadingType; // 'google' 或 'facebook'

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          setState(() => _loadingType = null);
          Get.back();
          Get.snackbar(
            '歡迎回來',
            '哈囉, ${state.user.displayName ?? "使用者"}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppTheme.accentPurple.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        } else if (state is AuthError) {
          setState(() => _loadingType = null);
          Get.snackbar(
            '登入失敗',
            state.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        } else if (state is Unauthenticated) {
          setState(() => _loadingType = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.5,
              colors: [
                Color(0xFF2A1B54),
                AppTheme.primaryDark,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.movie_creation_rounded, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                '加入電影人',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              
              // Subtitle
              const Text(
                '登入解鎖更多個人化推薦與服務',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 64),
              
              // Login Buttons
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isGlobalLoading = state is AuthLoading;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        _buildLoginButton(
                          context: context,
                          title: '使用 Google 帳號登入',
                          icon: Icons.g_mobiledata_rounded,
                          color: AppTheme.cardDark,
                          isLoading: isGlobalLoading && _loadingType == 'google',
                          isOtherLoading: isGlobalLoading && _loadingType != 'google',
                          onPressed: () {
                            setState(() => _loadingType = 'google');
                            context.read<AuthBloc>().add(SignInWithGoogleRequested());
                          },
                          hasBorder: true,
                        ),
                        const SizedBox(height: 16),
                        _buildLoginButton(
                          context: context,
                          title: '使用 Facebook 帳號登入',
                          icon: Icons.facebook_rounded,
                          color: const Color(0xFF1877F2),
                          isLoading: isGlobalLoading && _loadingType == 'facebook',
                          isOtherLoading: isGlobalLoading && _loadingType != 'facebook',
                          onPressed: () {
                            setState(() => _loadingType = 'facebook');
                            context.read<AuthBloc>().add(SignInWithFacebookRequested());
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required bool isOtherLoading,
    required VoidCallback onPressed,
    bool hasBorder = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (isLoading || isOtherLoading) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: hasBorder
                ? BorderSide(color: Colors.white.withOpacity(0.1), width: 1)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: icon == Icons.g_mobiledata_rounded ? 32 : 24, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
