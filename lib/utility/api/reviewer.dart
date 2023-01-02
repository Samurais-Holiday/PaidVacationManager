import 'package:in_app_review/in_app_review.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';

/// レビュー依頼の表示を行うクラス
class Reviewer {
  /// 依頼を行う間隔
  static Duration duration = const Duration(days: 90);

  /// 特定の条件を満たした場合にレビュー依頼の表示を行う
  static Future<void> requestShow() async {
    final DateTime? latestRequest = await LocalStorageManager.readLatestRequestReviewDate();
    if (latestRequest == null
        || DateTime.now().isAfter(latestRequest.add(duration))) {
      await show();
    }
  }

  /// レビュー依頼の表示を行う
  static Future<void> show() async {
    if (await InAppReview.instance.isAvailable()) {
      await InAppReview.instance.requestReview();
      await LocalStorageManager.writeLatestRequestReviewDate(DateTime.now());
    }
  }
}