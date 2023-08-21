import 'acquisition.dart';
import 'acquisition_day.dart';
import 'acquisition_half.dart';
import 'acquisition_hours.dart';
import 'am_pm.dart';
import 'date.dart';

/// 有給取得情報インスタンス生成クラス
class AcquisitionFactory {
  /// シングルトンインスタンス
  static AcquisitionFactory? _instance;

  /// プライベートコンストラクタ
  AcquisitionFactory._internal();

  /// インスタンス取得
  static get instance {
    _instance ??= AcquisitionFactory._internal();
    return _instance;
  }

  /// 取得情報インスタンス生成
  Acquisition create({required Date date, AmPm? amPm, int? hours, String description = ''}) {
    return amPm != null ? AcquisitionHalf(date: date, amPm: amPm, description: description)
        : hours != null ? AcquisitionHours(date: date, hours: hours, description: description)
        : AcquisitionDay(date: date, description: description);
  }
}