import 'date.dart';

/// 付与日数情報
class GivenDays {
  /// 付与日数
  final int _days;
  /// 付与日
  final Date _start;

  /// コンストラクタ
  GivenDays({required int days, required Date start})
      : _days = days, _start = start;

  /// 付与日数取得
  int get days => _days;

  /// 付与日取得
  Date get start => _start;

  /// 最終日取得
  Date get end {
    final end = Date(_start.year + 2, _start.month, _start.day);
    end.add(const Duration(days: -1));
    return end;
  }

}