/// 付与日数データクラス
class GivenDaysInfo {
  /// 付与日数データ
  late int givenDays;
  /// 付与日
  late DateTime givenDate;
  /// 失効日
  late DateTime lapseDate;

  /// コンストラクタ
  GivenDaysInfo(this.givenDays, this.givenDate, [DateTime? lapseDate]) :
      lapseDate = lapseDate ?? DateTime(givenDate.year + 2, givenDate.month, givenDate.day);
}