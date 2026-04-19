import 'package:firebase_database/firebase_database.dart';

class RatingService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// 取得某部電影的即時評分資料流
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

  /// 送出或更新評分 (透過 Transaction 避免並發寫入錯誤)
  Future<void> submitRating({
    required int movieId,
    required String uid,
    required double newRating,
  }) async {
    final ref = _db.ref('movie_ratings/$movieId');

    await ref.runTransaction((Object? currentData) {
      // 首次有人評分
      if (currentData == null) {
        return Transaction.success({
          'averageRating': newRating,
          'ratingCount': 1,
          'users': {
            uid: newRating,
          }
        });
      }

      // 轉換資料格式
      Map<String, dynamic> movieData = Map<String, dynamic>.from(currentData as Map);
      Map<String, dynamic> users = movieData['users'] != null 
          ? Map<String, dynamic>.from(movieData['users'] as Map) 
          : {};

      double oldRating = 0.0;
      bool isUpdate = users.containsKey(uid);
      if (isUpdate) {
        oldRating = (users[uid] as num).toDouble();
      }

      int count = (movieData['ratingCount'] as num?)?.toInt() ?? 0;
      double average = (movieData['averageRating'] as num?)?.toDouble() ?? 0.0;

      double totalSum = average * count;
      
      if (isUpdate) {
        // 如果是更新，減去舊分數，加上新分數
        totalSum = totalSum - oldRating + newRating;
      } else {
        // 如果是新評分，加上新分數並增加人數
        totalSum = totalSum + newRating;
        count += 1;
      }

      // 重新計算平均值
      average = count > 0 ? (totalSum / count) : 0.0;

      // 更新使用者紀錄與統計數據
      users[uid] = newRating;
      movieData['users'] = users;
      movieData['ratingCount'] = count;
      movieData['averageRating'] = average;

      return Transaction.success(movieData);
    });
  }
}
