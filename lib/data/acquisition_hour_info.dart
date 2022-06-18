import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:paid_vacation_manager/data/paid_vacation_time.dart';

/// 時間単位の有給取得情報
class AcquisitionHourInfo {
  /// 時間単位有給取得データ
  /// key: 取得日
  /// value: first: 取得時間, last: 取得理由
  final Map<DateTime, Pair<int, String>> _acquisitionHourInfo = <DateTime, Pair<int, String>>{};
  Map<DateTime, Pair<int, String>> get acquisitionList => _acquisitionHourInfo;

  /// 取得データ追加
  /// 既に存在する場合は設定しない
  bool add({
      required final DateTime date,
      required final int hour,
      final String reason = '',}) {

    if (_acquisitionHourInfo.containsKey(date)) {
      return false;
    }
    _acquisitionHourInfo[date] = Pair(hour, reason);
    return true;
  }

  /// データを削除する
  /// データがない場合はfalse
  bool delete(final DateTime date) {
    if (!_acquisitionHourInfo.containsKey(date)) {
      return false;
    }
    _acquisitionHourInfo.remove(date);
    return true;
  }

  /// 有給取得日数の取得
  PaidVacationTime get acquisitionDays {
    int returnHours = 0;
    for (var element in _acquisitionHourInfo.values) {
      returnHours += element.first;
    }
    return PaidVacationTime(hours: returnHours);
  }

  /// 有給取得時間の取得(特定の期間)
  int acquisitionHours({
      required final DateTime beginDate,
      required final DateTime endDate }) {
    int returnHours = 0;
    _acquisitionHourInfo.forEach((key, value) {
      if ((beginDate.isBefore(key) || key.isAtSameMomentAs(beginDate))
            && (key.isBefore(endDate) || key.isAtSameMomentAs(endDate))) {
        returnHours += value.first;
      }
    });
    return returnHours;
  }
}