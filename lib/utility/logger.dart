import 'dart:developer';

/// ロガークラス
/// levelは https://github.com/dart-lang/logging/blob/master/lib/src/level.dart を参照
class Logger {
  /// インスタンス生成不可
  Logger._();

  /// デバッグログ
  static void debug(final String message)
      => log(message, level: 500, time: DateTime.now());

  /// 情報ログ
  static void info(final String message)
      => log(message, level: 800, time: DateTime.now());

  /// 警告ログ
  static void warn(final String message)
      => log(message, level: 900, time: DateTime.now());

  /// エラーログ
  static void error(final String message)
      => log(message, level: 1000, time: DateTime.now());
}