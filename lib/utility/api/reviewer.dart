import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';
import 'package:paid_vacation_manager/utility/information_dialog.dart';

/// レビュー依頼の表示を行うクラス
class Reviewer {
  /// 依頼を行う間隔
  static Duration duration = const Duration(days: 90);

  /// 特定の条件を満たした場合にレビュー依頼の表示を行う
  static Future<void> requestShow({required BuildContext context}) async {
    final DateTime? latestRequest = await LocalStorageManager.readLatestRequestReviewDate();
    if (await InAppReview.instance.isAvailable()
        && (latestRequest == null || DateTime.now().isAfter(latestRequest.add(duration)))) {
      await show(context: context);
    }
  }

  /// レビュー依頼の表示を行う
  static Future<void> show({required BuildContext context}) async {
    if (await InAppReview.instance.isAvailable()) {
      await InAppReview.instance.requestReview();
      await LocalStorageManager.writeLatestRequestReviewDate(DateTime.now());
    } else {
      InformationDialog.show(context: context, info: 'このデバイスではレビューの送信が出来ません');
    }
  }
}