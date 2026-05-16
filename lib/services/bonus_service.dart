import 'package:firebase_database/firebase_database.dart';
import '../models/bonus_report.dart';

class BonusService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String _nodeName = 'bonus_reports';

  /// 提交特典回報
  Future<void> submitReport(BonusReport report) async {
    final ref = _database.ref('$_nodeName/${report.movieId}/${report.cinemaName}').push();
    await ref.set(report.toJson()..['id'] = ref.key);
  }

  /// 取得特定電影與影城的最新特典狀態
  Stream<List<BonusReport>> getReports(String movieId, String cinemaName) {
    return _database
        .ref('$_nodeName/$movieId/$cinemaName')
        .orderByChild('timestamp')
        .limitToLast(5)
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final reports = data.values.map((v) => BonusReport.fromJson(v as Map<dynamic, dynamic>)).toList();
      // 由新到舊排序
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  /// 取得特定電影所有影城的特典狀態摘要
  Stream<Map<String, BonusReport>> getMovieBonusSummary(String movieId) {
    return _database.ref('$_nodeName/$movieId').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};

      final Map<String, BonusReport> summary = {};
      data.forEach((cinemaName, cinemaData) {
        if (cinemaData is Map) {
          final reports = cinemaData.values
              .map((v) => BonusReport.fromJson(v as Map<dynamic, dynamic>))
              .toList();
          if (reports.isNotEmpty) {
            reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            summary[cinemaName] = reports.first;
          }
        }
      });
      return summary;
    });
  }
}
