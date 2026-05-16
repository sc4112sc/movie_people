import 'package:firebase_database/firebase_database.dart';
import '../models/rating_entry.dart';

class RatingService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  static const int _pageSize = 20;

  /// 取得某部電影的即時評分資料流（聚合統計）
  Stream<Map<String, dynamic>> getRatingStream(int movieId) {
    final ref = _db.ref('movie_ratings/$movieId');
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return {
          'averageRating': 0.0,
          'ratingCount': 0,
          'users': <String, dynamic>{},
        };
      }
      return {
        'averageRating': (data['averageRating'] as num?)?.toDouble() ?? 0.0,
        'ratingCount': (data['ratingCount'] as num?)?.toInt() ?? 0,
        'users': data['users'] != null
            ? Map<String, dynamic>.from(data['users'] as Map)
            : <String, dynamic>{},
      };
    });
  }

  /// 送出或更新評分（Transaction 保證並發安全），並寫入歷史紀錄
  Future<void> submitRating({
    required int movieId,
    required String uid,
    required double newRating,
    String? comment,
    String? displayName,
    String? userEmail,
    String? userPhotoUrl,
  }) async {
    final aggregateRef = _db.ref('movie_ratings/$movieId');
    final historyRef = _db.ref('rating_history/$movieId').push();
    final String newHistoryKey = historyRef.key ?? '';
    String? oldHistoryKey;

    // 1. 用 Transaction 更新聚合統計
    await aggregateRef.runTransaction((Object? currentData) {
      if (currentData == null) {
        return Transaction.success({
          'averageRating': newRating,
          'ratingCount': 1,
          'users': {
            uid: {
              'rating': newRating,
              'comment': comment,
              'lastHistoryKey': newHistoryKey
            }
          },
        });
      }

      Map<String, dynamic> movieData =
          Map<String, dynamic>.from(currentData as Map);
      Map<String, dynamic> users = movieData['users'] != null
          ? Map<String, dynamic>.from(movieData['users'] as Map)
          : {};

      double oldRating = 0.0;
      bool isUpdate = users.containsKey(uid);
      if (isUpdate) {
        final userData = users[uid];
        if (userData is Map) {
          oldRating = (userData['rating'] as num?)?.toDouble() ?? 0.0;
          oldHistoryKey = userData['lastHistoryKey'] as String?;
        } else if (userData is num) {
          oldRating = userData.toDouble();
        }
      }

      int count = (movieData['ratingCount'] as num?)?.toInt() ?? 0;
      double average = (movieData['averageRating'] as num?)?.toDouble() ?? 0.0;
      double totalSum = average * count;

      if (isUpdate) {
        totalSum = totalSum - oldRating + newRating;
      } else {
        totalSum = totalSum + newRating;
        count += 1;
      }

      average = count > 0 ? (totalSum / count) : 0.0;
      
      users[uid] = {
        'rating': newRating,
        'comment': comment,
        'lastHistoryKey': newHistoryKey,
      };
      
      movieData['users'] = users;
      movieData['ratingCount'] = count;
      movieData['averageRating'] = average;

      return Transaction.success(movieData);
    });

    // 2. 如果有舊紀錄，先刪除它
    if (oldHistoryKey != null && oldHistoryKey!.isNotEmpty) {
      await _db.ref('rating_history/$movieId/$oldHistoryKey').remove();
    }

    // 3. 寫入新的歷史紀錄節點
    final entry = RatingEntry(
      id: newHistoryKey,
      movieId: movieId.toString(),
      uid: uid,
      rating: newRating,
      comment: comment,
      timestamp: DateTime.now(),
      displayName: displayName,
      userEmail: userEmail,
      userPhotoUrl: userPhotoUrl,
    );
    await _db.ref('rating_history/$movieId/$newHistoryKey').set(entry.toJson());
  }

  /// 分頁取得評分歷史（最新在前）
  /// [lastKey] 為上次最後一筆的 Firebase push key
  Future<List<RatingEntry>> getRatingHistory(
    int movieId, {
    String? lastKey,
  }) async {
    try {
      final ref = _db.ref('rating_history/$movieId');
      Query query = ref.orderByKey().limitToLast(_pageSize);

      if (lastKey != null) {
        query = ref.orderByKey().endBefore(lastKey).limitToLast(_pageSize);
      }

      final snapshot = await query.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final entries = <RatingEntry>[];
      
      data.forEach((key, value) {
        if (value is Map) {
          entries.add(RatingEntry.fromJson(key.toString(), value));
        }
      });

      // 最新（push key 較大）的排在前面
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (e) {
      print('❌ [RatingService] Error fetching history: $e');
      return [];
    }
  }
}
