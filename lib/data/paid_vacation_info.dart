import 'dart:collection';
import 'dart:core';
import 'dart:developer';
import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:paid_vacation_manager/config/configure.dart';
import 'package:paid_vacation_manager/data/acquisition_hour_info.dart';
import 'package:paid_vacation_manager/data/acquisition_one_day_info.dart';
import 'package:paid_vacation_manager/data/acquisition_half_info.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_time.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';
import 'package:tuple/tuple.dart';

/// 各付与期間の有給データクラス
class PaidVacationInfo {
  /// 付与日数データ
  late final GivenDaysInfo _givenDaysInfo;
  /// 有給取得日データ
  final _oneDayInfo = AcquisitionOneDayInfo();
  /// 半休取得日データ
  final _halfInfo = AcquisitionHalfInfo();
  /// 時間単位取得データ
  final _hourInfo = AcquisitionHourInfo();

  /// コンストラクタ
  PaidVacationInfo(final GivenDaysInfo givenDaysInfo) : _givenDaysInfo = givenDaysInfo;

  /// 付与日数設定
  /// 付与日数 < 取得日数 の場合は設定しない
  bool setGivenDays(final int newDays) {
    final newGivenDays = PaidVacationTime(days: newDays);
    if (newGivenDays < (_oneDayInfo.acquisitionDays + _halfInfo.acquisitionDays + _hourInfo.acquisitionDays)) {
      return false;
    }
    _givenDaysInfo.givenDays = newGivenDays;
    return true;
  }
  /// 付与日数取得
  PaidVacationTime get givenDays => _givenDaysInfo.givenDays;

  /// 付与日設定
  set givenDate(final DateTime date) => _givenDaysInfo.givenDate = date;
  /// 付与日取得
  DateTime get givenDate => _givenDaysInfo.givenDate;


  /// 失効日設定
  /// 付与日から2年未満は設定不可
  bool setLapseDate(DateTime date) {
    final givenDate = _givenDaysInfo.givenDate;
    final guaranteeDate = DateTime(givenDate.year + 2, givenDate.month, givenDate.day);
    if (date.isBefore(guaranteeDate)) {
      log('失効日設定失敗 lapseDate: ${date.toString()}');
      return false;
    }
    _givenDaysInfo.lapseDate = date;
    log('失効日設定成功 lapseDate: ${_givenDaysInfo.lapseDate.toString()}');
    return true;
  }
  /// 失効日取得
  DateTime get lapseDate => _givenDaysInfo.lapseDate;


  /// 有給取得日リスト取得(日付が古い順)
  /// key: 取得日・AM/PM・取得時間(H), value: 取得理由
  Map<Tuple3<DateTime, AmPm?, int?>, String> sortedAcquisitionDate() {
    final returnList = SplayTreeMap<Tuple3<DateTime, AmPm?, int?>, String>((a, b) {
      final result = a.item1.compareTo(b.item1);
      if (result == 0) {
        // 取得日が同じ場合
        if (a.item2 != null && b.item2 != null) {
          // 午前/午後の比較
          return a.item2 == AmPm.pm ? 1 : -1; // 数が大きいほうが後ろにくる
        } else {
          // 半休と、時間単位の比較
          return a.item2 == AmPm.pm && b.item3 != null ? 1 : -1;
        }
      }
      return result;
    });

    // 全休のデータを追加
    _oneDayInfo.acquisitionList.forEach((key, value) {
      returnList[Tuple3(key, null, null)] = value;
    });
    // 半休のデータを追加
    _halfInfo.acquisitionList.forEach((key, value) {
      returnList[Tuple3(key.first, key.last, null)] = value;
    });
    // 時間単位取得データを追加
    _hourInfo.acquisitionList.forEach((key, value) {
      returnList[Tuple3(key, null, value.first)] = value.last;
    });
    return returnList;
  }

  /// 有給取得情報削除
  /// 半休の場合は amPm を指定すること
  bool deleteAcquisitionInfo({
      required final DateTime date,
      AmPm? amPm,
      bool isHour = false }) {
    if (amPm == null && !isHour) {
      return _oneDayInfo.delete(date);
    } else if (amPm != null && !isHour) {
      return _halfInfo.delete(date, amPm);
    } else if (isHour) {
      return _hourInfo.delete(date);
    } else {
      return false;
    }
  }

  /// 有給取得
  /// 半休の場合は amPm を指定すること
  /// 時間単位の場合は hours を指定すること
  /// 有効期間外の場合は設定しない
  bool acquisitionVacation({
      required final DateTime date,
      final AmPm? amPm,
      final int? hours,
      final String reason = ''}) {

    // 有効期間内か
    if (!isValidDay(date)) {
      log('$acquisitionVacation\n全休取得失敗 (有効期間外を取得しようとしています '
          '(actual: $date, expected: $givenDate ~ $lapseDate))');
      return false;
    }
    // 全休の場合
    if (amPm == null && hours == null) {
      return _acquisitionOneDay(date: date, reason: reason);
    }
    // 半休の場合
    else if (amPm != null) {
      return _acquisitionHalf(date: date, amPm: amPm, reason: reason);
    }
    // 時間単位の場合
    else if (hours != null) {
      return _acquisitionHour(date: date, hours: hours, reason: reason);
    }
    // 該当なし
    else {
      return false;
    }
  }

  /// 有給取得(全休)
  /// 下記の場合は設定しない
  ///   ・半休に同じ日付のデータがある
  ///   ・時間単位に同じ日付のデータがある
  ///   ・残り日数が足りない
  bool _acquisitionOneDay({required final DateTime date, final String reason = ''}) {
    // 半休の取得情報に取得日が重なるデータがある場合は設定しない
    final keys = _halfInfo.acquisitionList.keys;
    final guard = Pair(DateTime(0), AmPm.am); // 番兵
    if (keys.firstWhere((key) => key.first == date, orElse: () => guard) != guard) {
      log('${_acquisitionOneDay.toString()}\n全休取得失敗 (半休に同じ日付のデータが存在します (${date.toString()}))');
      return false;
    }
    // 時間単位での取得情報に取得日が重なるデータがある場合は設定しない
    if (_hourInfo.acquisitionList.keys.contains(date)) {
      log('$_acquisitionOneDay\n全休取得失敗 (時間単位での取得データに同じ日付が存在します ($date))');
      return false;
    }
    // 残り日数が足りない場合は設定しない
    if (remainingDays.days < 1) {
      log('${_acquisitionOneDay.toString()}\n全休取得失敗 (残りの有給数が足りません (actual: $remainingDays, expected: 1~))');
      return false;
    }
    return _oneDayInfo.add(date: date, reason: reason);
  }

  /// 半休取得
  /// 半休と時間単位は同日に取得出来るようにする
  /// 下記の場合は設定しない
  ///   ・全休に同じ日付のデータがある
  ///   ・残り日数が足りない
  bool _acquisitionHalf({required final DateTime date, required final AmPm amPm, final String reason = ''}) {
    // 全休の取得情報に取得日が重なるデータがあるか
    if (_oneDayInfo.acquisitionList.keys.contains(date)) {
      log('${_acquisitionHalf.toString()}\n半休取得失敗 (全休に取得日が重なるデータがあります (取得日: ${date.toString()}))');
      return false;
    }
    // 残り日数が足りるか
    if (remainingDays < PaidVacationTime(hours: Configure.instance.hoursPerHalf)) {
      log('${_acquisitionHalf.toString()}\n半休取得失敗 (残り日数が足りません (actual: $remainingDays, expected: 0.5~))');
      return false;
    }
    return _halfInfo.add(date: date, amPm: amPm, reason: reason);
  }

  /// 時間単位有給取得
  /// 半休と時間単位は同日に取得出来るようにする
  /// 下記の場合には設定しない
  ///   ・全休に同じ取得日のデータがある
  ///   ・残り日数が足りない場合
  ///   ・今年度の時間単位の取得が5時間を超える場合
  bool _acquisitionHour({
      required final DateTime date,
      required final int hours,
      required final String reason}) {

    // 全休に同じ取得日のデータがあれば失敗
    if (_oneDayInfo.acquisitionList.containsKey(date)) {
      return false;
    }
    // 残り日数が足りれば設定する
    return PaidVacationTime(hours: hours) <= remainingDays
        ? _hourInfo.add(date: date, hour: hours, reason: reason)
        : false;
  }

  /// 取得日上書き
  bool updateAcquisitionInfo({
      required final DateTime prevDate, required final DateTime newDate,
      final AmPm? prevAmPm, final AmPm? newAmPm,
      final int? prevHours, final int? newHours,
      final String newReason = ''}) {

    log('${updateAcquisitionInfo.toString()}\n取得データ更新開始');
    // 前回の理由を保持しておく
    final String? prevReason = (prevAmPm == null && prevHours == null) ? _oneDayInfo.acquisitionList[prevDate]
        : prevAmPm != null ? _halfInfo.acquisitionList[Pair(prevDate, prevAmPm)]
        : _hourInfo.acquisitionList[prevDate]?.last;
    if (prevReason == null) {
      log('${updateAcquisitionInfo.toString()}\n前回データが見つかりません');
      return false;
    }
    // 前回データ削除
    deleteAcquisitionInfo(date: prevDate, amPm: prevAmPm, isHour: prevHours != null);
    // 新しいデータを追加
    final isSuccess = (newAmPm == null && newHours == null) ? _acquisitionOneDay(date: newDate, reason: newReason)
        : newAmPm != null ? _acquisitionHalf(date: newDate, amPm: newAmPm, reason: newReason)
        : newHours != null ?_acquisitionHour(date: newDate, hours: newHours, reason: newReason)
        : false;
    if (isSuccess) {
      log('$updateAcquisitionInfo\n取得データ更新成功 (取得日: $newDate ($newAmPm, ${newHours}H))');
      return true;
    } else {
      // 設定できなかった場合は元の設定に戻す
      log('$updateAcquisitionInfo\n取得情報の更新失敗 再設定します (取得日: $newDate ($newAmPm, ${newHours}H))');
      if (prevAmPm == null && prevHours == null) {
        _oneDayInfo.add(date: prevDate, reason: prevReason);
      } else if (prevAmPm != null) {
        _halfInfo.add(date: prevDate, amPm: prevAmPm, reason: prevReason);
      } else if (prevHours != null) {
        _hourInfo.add(date: prevDate, hour: prevHours, reason: prevReason);
      }
      return false;
    }
  }

  /// 時間単位での取得時間(期間の指定)
  int acquisitionHours({
    required final DateTime beginDate,
    required final DateTime endDate })
        => _hourInfo.acquisitionHours(beginDate: beginDate, endDate: endDate);

  /// 取得日数取得
  PaidVacationTime get acquisitionTotal
      => _oneDayInfo.acquisitionDays + _halfInfo.acquisitionDays + _hourInfo.acquisitionDays;
  /// 全休取得回数取得
  int get acquisitionOneDayCount => _oneDayInfo.acquisitionDays.days;
  /// 半休取得回数取得
  int get acquisitionHalfCount => _halfInfo.acquisitionList.length;
  /// 残り日数取得
  PaidVacationTime get remainingDays => givenDays - acquisitionTotal;

  /// 指定した日が有効期間内か
  bool isValidDay(DateTime date) {
    return (_givenDaysInfo.givenDate == date || _givenDaysInfo.givenDate.isBefore(date))
        && date.isBefore(_givenDaysInfo.lapseDate);
  }
}