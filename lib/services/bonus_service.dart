import 'package:firebase_database/firebase_database.dart';
import '../models/bonus_report.dart';

class BonusService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String _nodeName = 'bonus_reports';
  static const int _pageSize = 20;

  /// 提交特典回報 (以 userId 為鍵，確保每個帳號只保留最新的一筆)
  Future<void> submitReport(BonusReport report) async {
    if (report.userId == null) return;
    
    final ref = _database
        .ref('$_nodeName/${report.movieId}/${report.cinemaName}/${report.format}/${report.userId}');
    await ref.set(report.toJson()..['id'] = report.userId);
  }

  /// 取得特定電影、影城與廳別的最新特典狀態（Stream）
  Stream<List<BonusReport>> getReports(String movieId, String cinemaName, String format) {
    return _database
        .ref('$_nodeName/$movieId/$cinemaName/$format')
        .orderByChild('timestamp')
        .limitToLast(1)
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? data =
          event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      final reports = data.values
          .map((v) => BonusReport.fromJson(v as Map<dynamic, dynamic>))
          .toList();
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  /// 分頁取得特典回報歷史（最新在前）
  Future<List<BonusReport>> getBonusHistory(
    String movieId,
    String cinemaName,
    String format, {
    String? lastTimestamp,
  }) async {
    Query query = _database
        .ref('$_nodeName/$movieId/$cinemaName/$format')
        .orderByChild('timestamp')
        .limitToLast(_pageSize);

    if (lastTimestamp != null) {
      query = _database
          .ref('$_nodeName/$movieId/$cinemaName/$format')
          .orderByChild('timestamp')
          .endBefore(lastTimestamp)
          .limitToLast(_pageSize);
    }

    final snapshot = await query.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final reports = data.values
        .map((v) => BonusReport.fromJson(Map<dynamic, dynamic>.from(v as Map)))
        .toList();

    reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return reports;
  }

  /// 取得特定電影所有影城所有廳別的特典狀態摘要（Stream）
  /// 返回格式：{ "影城名": { "廳別名": BonusReport } }
  Stream<Map<String, Map<String, BonusReport>>> getMovieBonusSummary(String movieId) {
    return _database.ref('$_nodeName/$movieId').onValue.map((event) {
      final Map<dynamic, dynamic>? data =
          event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};

      final Map<String, Map<String, BonusReport>> summary = {};
      data.forEach((cinemaName, cinemaData) {
        if (cinemaData is Map) {
          final Map<String, BonusReport> formatSummary = {};
          cinemaData.forEach((formatName, formatData) {
            if (formatData is Map) {
              final reports = formatData.values
                  .map((v) => BonusReport.fromJson(v as Map<dynamic, dynamic>))
                  .toList();
              if (reports.isNotEmpty) {
                reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                formatSummary[formatName] = reports.first;
              }
            }
          });
          if (formatSummary.isNotEmpty) {
            summary[cinemaName] = formatSummary;
          }
        }
      });
      return summary;
    });
  }
}
