import 'acquisition.dart';
import 'acquisition_hours.dart';
import 'paid_duration.dart';
import 'am_pm.dart';
import 'date.dart';

/// 有給取得情報(半休)
class AcquisitionHalf extends Acquisition {
  /// 午前/午後
  final AmPm _amPm;

  /// コンストラクタ
  /// date: 取得日
  /// amPm: 午前/午後
  /// description: 説明
  AcquisitionHalf({required Date date, required AmPm amPm, String description = ''})
      : _amPm = amPm,
        super(
            date: date,
            duration: PaidDuration(days: 0.5),
            description: description);

  /// 午前/午後
  AmPm get amPm => _amPm;

  /// 表示タイトルの補足情報
  @override
  String? subTitle()
      => _amPm == AmPm.am
          ? '午前'
          : '午後';

  /// 昇順定義
  @override
  int? localCompareTo(final Acquisition other) {
    if (other is AcquisitionHours) {
      return _amPm == AmPm.am
          ? -1
          : 1;
    }
    if (other is AcquisitionHalf) {
      return _amPm == other._amPm ? 0
          : _amPm == AmPm.am ? -1
          : 1;
    }
    return null;
  }
}