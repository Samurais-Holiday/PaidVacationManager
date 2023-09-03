/// 日付に関する情報を管理するクラス
class Date extends DateTime {
  /// 曜日への変換テーブル
  static const Map<int, String> _weekDayToString = {
    DateTime.monday    : '月',
    DateTime.tuesday   : '火',
    DateTime.wednesday : '水',
    DateTime.thursday  : '木',
    DateTime.friday    : '金',
    DateTime.saturday  : '土',
    DateTime.sunday    : '日',
  };

  /// コンストラクタ
  Date(int year, [int month = 1, int day = 1]) : super(year, month, day);

  /// DateTimeからインスタンス生成
  static Date fromDateTime(DateTime dateTime)
      => Date(dateTime.year, dateTime.month, dateTime.day);

  /// 今日の日付のインスタンス生成
  static Date today() {
    final now = DateTime.now();
    return Date(now.year, now.month, now.day);
  }

  /// 曜日取得
  String get weekdayText => _weekDayToString[weekday]!;

  /// 同値比較
  bool isSame(Date other)
      => year == other.year && month == other.month && day == other.day;

  /// 不同値比較
  bool isNotSame(Date other) => !isSame(other);

  @override
  Date add(Duration duration) => fromDateTime(super.add(duration));

  @override
  Date subtract(Duration duration) => fromDateTime(super.subtract(duration));
}