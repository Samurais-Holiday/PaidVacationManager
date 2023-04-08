import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';

/// 設定情報を保持するクラス
class Configure {
  /// シングルトンインスタンス
  static final _singletonInstance = Configure._internal();
  /// Googleカレンダーとの同期設定
  bool isSyncGoogleCalendar = false;
  /// 1日の労働時間
  int hoursPerOneDay = 8;
  /// 半休の時間
  num get hoursPerHalf => hoursPerOneDay / 2;
  /// 広告を非表示にするか
  bool hideAd = false;

  /// プライベートコンストラクタ
  Configure._internal();

  /// ストレージから値読み込み
  Future<void> load() async {
    LocalStorageManager.readIsSyncGoogleCalendar().then((value) => isSyncGoogleCalendar = value);
    LocalStorageManager.readHideAd().then((value) => hideAd = value);
  }

  /// インスタンス取得
  static Configure get instance => _singletonInstance;
}