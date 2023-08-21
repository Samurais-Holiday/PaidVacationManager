import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../model/settings.dart';

/// レビュー依頼の表示を行うクラス
class Reviewer {
  /// 依頼を行う間隔
  static Duration duration = const Duration(days: 90);

  /// 特定の条件を満たした場合にレビュー依頼の表示を行う
  ///
  /// 依頼成功trueを返却し、依頼失敗時はfalseを返却する
  static Future<bool> requestShow({required BuildContext context, required Settings settings}) async {
    if (!await InAppReview.instance.isAvailable()) {
      return false;
    }
    final DateTime? latestRequest = settings.latestReviewRequest;
    if (latestRequest != null && DateTime.now().isBefore(latestRequest.add(duration))) {
      return false;
    }
    InAppReview.instance.requestReview();
    settings.latestReviewRequest = DateTime.now();
    return true;
  }
}