import 'acquisition.dart';
import 'error_code.dart';

/// カレンダーアプリ同期機能
abstract class CalendarSync {
  /// 有給取得
  Future<ErrorCode> acquire(Acquisition acquisition);
  /// 有給取得情報更新
  Future<ErrorCode> updateAcquisition({required Acquisition before, required Acquisition after});
  /// 有給取得情報削除
  Future<void> delete(Acquisition acquisition);
}