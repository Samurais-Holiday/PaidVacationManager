import 'acquisition.dart';
import 'paid_duration.dart';
import 'date.dart';

/// 有給取得情報(全休)
class AcquisitionDay extends Acquisition {
  /// コンストラクタ
  /// date: 取得日
  /// description: 説明
  AcquisitionDay({required Date date, String description = ''})
      : super(
          date: date,
          duration: PaidDuration(days: 1),
          description: description);
}