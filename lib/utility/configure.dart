import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';

/// 設定情報を保持するクラス
class Configure {
  /// プライベートコンストラクタ
  Configure._internal() {
    LocalStorageManager.readIsSyncGoogleCalendar().then((value) => isSyncGoogleCalendar = value);
  }

  /// シングルトンインスタンス
  static final _singletonInstance = Configure._internal();
  static Configure get instance => _singletonInstance;

  /// Googleカレンダーとの同期設定(初期値OFF)
  bool isSyncGoogleCalendar = false;
}