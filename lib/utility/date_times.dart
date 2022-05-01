/// DateTimeクラスを使用した機能を提供する
class DateTimes {
  /// DateTimeの文字列の長さ
  static final length = DateTime(2020, 1, 1).toString().length;

  /// 月ごとの最終日
  /// うるう年は考慮しない
  static Map<int, int> endOfMonth = {
    1:31, 2:30, 3:31, 4:30, 5:31, 6:30, 7:31, 8:31, 9:30, 10:31, 11:30, 12:31,
  };
}