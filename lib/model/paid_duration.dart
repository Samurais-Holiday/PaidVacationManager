/// 有給における日数を表現するクラス
class PaidDuration {
  /// 取得日数
  num _days;
  /// 時間単位での取得時間
  int _hours;

  /// コンストラクタ
  /// days: 取得日数
  /// hours: 時間単位での取得時間
  PaidDuration({num days = 0, int hours = 0})
      : _days = days, _hours = hours;

  /// 表示用文字列
  String toLabelText([num workingHours = 8])
      => '${days(workingHours).toStringAsFixed(1)} 日  ${hours(workingHours)} 時間';

  /// 時間
  /// workingHours: 所定労働時間数
  int hours([num workingHours = 8])
      => _hours % workingHours.ceil();

  /// 時間
  int get totalHours => _hours;

  /// 日数
  /// workingHours: 所定労働時間数
  num days([num workingHours = 8]) {
    if (_hours == 0) {
      return _days;
    }
    var result = _days + _hours ~/ workingHours.ceil();
    if (_hours.isNegative) {
      result--;
    }
    return result;
  }

  /// 追加
  PaidDuration add(final PaidDuration other) {
    _days += other._days;
    _hours += other._hours;
    return this;
  }

  PaidDuration operator +(final PaidDuration other)
      => PaidDuration(days: _days + other._days, hours: _hours + other._hours);

  PaidDuration operator -(final PaidDuration other)
      => PaidDuration(days: _days - other._days, hours: _hours - other._hours);

  bool isCover(final PaidDuration other, [num workingHours = 8])
      => other.days(workingHours) < days(workingHours)
          || (days(workingHours) == other.days(workingHours) && other.hours(workingHours) <= hours(workingHours));
}