import 'package:flutter/material.dart';

import '../../model/error_code.dart';

/// ダイアログ表示機能
class Dialogs {
  /// インスタンス生成禁止
  Dialogs._internal();

  /// 列挙から文字列への変換テーブル
  static const Map<ErrorCode, String> _toErrorText = <ErrorCode, String>{
    ErrorCode.overlap : '他の有給取得と重複しています。',
    ErrorCode.alreadyExists : '既にデータが存在します。',
    ErrorCode.lackDays : '有給の日数が不足しています。',
    ErrorCode.outOfPeriod : '取得日が有効期間外です。',
    ErrorCode.syncCalendarFailed : '外部カレンダーアプリとの連携に失敗しました。',
  };

  /// エラーダイアログ表示
  static Future<void> showError({required BuildContext context, String? text, ErrorCode? errorCode})
      => show(
        context: context,
        title: Text('エラー', style: TextStyle(color: Theme.of(context).colorScheme.error),),
        text: text ?? (errorCode != null
                ? _toErrorText[errorCode] ?? '不明なエラーです'
                : ''),
      );

  /// 確認ダイアログ表示
  /// * 'OK'押下時、trueを返却
  /// * 'キャンセル'押下時、falseを返却
  static Future<bool> showConfirmation({required BuildContext context, required String text})
      => show(
          context: context,
          title: Text('確認', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          text: text,
          hasCancel: true,
      );

  /// ダイアログ表示
  /// * 'OK'押下時、trueを返却
  /// * 'キャンセル'押下時、falseを返却
  static Future<bool> show({required BuildContext context, Text? title, required String text, bool hasCancel = false}) async {
    final pressedOk = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: title,
          content: Text(text),
          actions: [
            if (hasCancel)
              TextButton(
                  onPressed: () => Navigator.pop<bool>(context, false),
                  child: Text('キャンセル', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error))
              ),
            TextButton(
                onPressed: () => Navigator.pop<bool>(context, true),
                child: Text('OK', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor),)
            )
          ],
        )
    );
    return pressedOk ?? false;
  }
}