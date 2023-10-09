import 'date.dart';
import 'paid_duration.dart';

/// 有給取得情報
abstract class Acquisition implements Comparable<Acquisition> {
  /// 取得日
  Date date;
  /// 時間単位での取得時間
  final PaidDuration _duration;
  /// 説明
  final String _description;

  /// コンストラクタ
  /// date: 取得日
  /// duration: 取得時間
  /// description: 説明
  Acquisition({required this.date, required PaidDuration duration, String description = ''})
      : _duration = duration, _description = description;

  /// 取得時間
  PaidDuration get duration => _duration;

  /// 説明
  String get description => _description;

  /// 表示タイトル
  String get title
      => subTitle() != null
          ? '${date.year}/${'${date.month}'.padLeft(2, '0')}/${'${date.day}'.padLeft(2, '0')} (${date.weekdayText}) (${subTitle()})'
          : '${date.year}/${'${date.month}'.padLeft(2, '0')}/${'${date.day}'.padLeft(2, '0')} (${date.weekdayText})';

  /// サブタイトル
  String? subTitle() => null;

  /// 昇順定義
  @override
  int compareTo(final Acquisition other) {
    final dateResult = date.compareTo(other.date);
    if (dateResult != 0) {
      return dateResult;
    }
    return localCompareTo(other) ?? dateResult;
  }

  /// 昇順定義
  /// サブクラスで必要な場合に実装すること
  int? localCompareTo(final Acquisition other) => null;
}