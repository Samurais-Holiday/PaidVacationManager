import 'acquisition.dart';
import 'acquisition_half.dart';
import 'paid_duration.dart';
import 'date.dart';

/// 有給取得情報(時間単位)
class AcquisitionHours extends Acquisition {
  /// コンストラクタ
  AcquisitionHours({required Date date, required int hours, String description = ''})
      : super(
          date: date,
          duration: PaidDuration(hours: hours),
          description: description);

  /// 表示タイトルの補足情報
  @override
  String? subTitle() => '${duration.hours()} 時間';

  /// 昇順定義
  @override
  int? localCompareTo(final Acquisition other) {
    if (other is AcquisitionHalf) {
      final amPmResult = other.localCompareTo(this);
      return amPmResult != null
          ? -amPmResult
          : null;
    }
    return null;
  }
}