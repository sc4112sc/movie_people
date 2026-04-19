import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../bloc/auth_bloc.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Success login, go back
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
          Get.snackbar(
            '登入失敗',
            state.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
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
              
              // Google Sign In Button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton(
                      onPressed: state is AuthLoading
                          ? null
                          : () {
                              context.read<AuthBloc>().add(SignInWithGoogleRequested());
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardDark,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (state is AuthLoading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
                              ),
                            )
                          else ...[
                            // Load a simple google icon or use standard icon
                            const Icon(Icons.g_mobiledata_rounded, size: 36, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              '使用 Google 帳號登入',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
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
}
