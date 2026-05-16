import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('隱私權政策'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. 資料收集', '我們收集您的電子郵件地址僅用於身份驗證與個人化功能。'),
            _buildSection('2. 位置資訊', '我們請求位置存取權限僅用於尋找您附近的電影院。您的位置資訊不會被儲存在伺服器上。'),
            _buildSection('3. 本地通知', '我們使用通知功能來提醒您感興趣的電影上映時間。'),
            _buildSection('4. 第三方服務', '我們使用 Firebase 作為後端服務商。相關隱私條款請參閱 Google Privacy Policy。'),
            const SizedBox(height: 40),
            Text(
              '最後更新日期：2026年5月17日',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
