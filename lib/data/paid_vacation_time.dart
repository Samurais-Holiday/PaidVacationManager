import 'package:paid_vacation_manager/config/configure.dart';

/// 有給における、日数、時間を保持するクラス
class PaidVacationTime {
  /// 日数
  late int _days;
  int get days => _days;
  /// 時間(0~1日の労働時間(h))
  late num _hours;
  num get hours => _hours;

  /// コンストラクタ
  /// hours は、0時間~1日の労働時間の間で値をとり、インスタンス生成時に自動で繰り上げ、繰り下げを行う
  /// 例）days = 0, hours = 15 ⇒ days == 1, hours == 7
  /// 例）days = 3, hours = -10 ⇒ days == 1, hours == 6
  PaidVacationTime({
      final int days = 0,
      final num hours = 0}) {
    if (hours < 0) {
      // 繰り下げ
      _days = days + hours ~/ Configure.instance.hoursPerOneDay;
      if (hours % Configure.instance.hoursPerOneDay != 0) {
        // 割り切れない場合は余り(hours)が負数のため、さらに繰り下げをする
        _days--;
      }
      _hours = hours % Configure.instance.hoursPerOneDay;
    } else if (Configure.instance.hoursPerOneDay <= hours) {
      // 繰り上げ
      _days = days + hours ~/ Configure.instance.hoursPerOneDay;
      _hours = hours % Configure.instance.hoursPerOneDay;
    } else {
      _days = days;
      _hours = hours;
    }
  }

  /// 0日0時間か
  bool isEmpty() => days == 0 && hours == 0;

  /// 0日0時間以外か
  bool isNotEmpty() => !isEmpty();

  /// 各演算子オーバーライド
  bool operator <(PaidVacationTime other)
      => days < other.days || (days == other.days && hours < other.hours);

  bool operator <=(PaidVacationTime other)
      => this < other || (days == other.days && hours == other.hours);

  PaidVacationTime operator +(PaidVacationTime other)
      => PaidVacationTime(days: days + other.days, hours: hours + other.hours);

  PaidVacationTime operator -(PaidVacationTime other)
      => PaidVacationTime(days: days - other.days, hours: hours - other.hours);
}