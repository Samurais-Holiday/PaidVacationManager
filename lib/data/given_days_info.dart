import 'package:paid_vacation_manager/data/paid_vacation_time.dart';

/// 付与日数データクラス
class GivenDaysInfo {
  /// 付与日数データ
  late PaidVacationTime givenDays;
  /// 付与日
  late DateTime givenDate;
  /// 失効日
  late DateTime lapseDate;

  /// コンストラクタ
  GivenDaysInfo(int days, this.givenDate, this.lapseDate)
      : givenDays = PaidVacationTime(days: days);
}