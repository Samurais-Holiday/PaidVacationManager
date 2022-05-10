import 'dart:collection';
import 'dart:core';
import 'dart:developer';
import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:paid_vacation_manager/data/acquisition_one_day_info.dart';
import 'package:paid_vacation_manager/data/acquisition_half_info.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';

/// 各付与期間の有給データクラス
class PaidVacationInfo {
  /// 付与日数データ
  late final GivenDaysInfo _givenDaysInfo;
  /// 有給取得日データ
  final _acquisitionDateInfo = AcquisitionOneDayInfo();
  /// 半休取得日データ
  final _acquisitionHalfInfo = AcquisitionHalfInfo();

  /// コンストラクタ
  PaidVacationInfo(GivenDaysInfo givenDaysInfo) : _givenDaysInfo = givenDaysInfo;

  /// 付与日数設定
  /// 付与日数 < 取得日数 の場合は設定しない
  bool setGivenDays(int days) {
    if (days < _acquisitionDateInfo.acquisitionDays + _acquisitionHalfInfo.acquisitionDays) {
      return false;
    }
    _givenDaysInfo.givenDays = days;
    return true;
  }
  /// 付与日数取得
  int get givenDays => _givenDaysInfo.givenDays;

  /// 付与日設定
  set givenDate(DateTime date) => _givenDaysInfo.givenDate = date;
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
  /// key: 取得日・AM/PM, value: 取得理由
  Map<Pair<DateTime, AmPm?>, String> sortedAcquisitionDate() {
    final returnList = SplayTreeMap<Pair<DateTime, AmPm?>, String>((a, b) {
      final result = a.first.compareTo(b.first);
      if (result == 0) {
        return a.last == AmPm.pm ? 1 : -1; // 数が大きいほうが後ろにくる
      }
      return result;
    });

    // 全休のデータを追加
    _acquisitionDateInfo.acquisitionList.forEach((key, value) {
      returnList[Pair(key, null)] = value;
    });
    // 半休のデータを追加
    returnList.addAll(_acquisitionHalfInfo.acquisitionList);
    return returnList;
  }

  /// 有給取得情報削除
  /// 半休の場合は amPm を指定すること
  bool deleteAcquisitionInfo(DateTime date, AmPm? amPm) {
    if (amPm == null) {
      return _acquisitionDateInfo.delete(date);
    } else {
      return _acquisitionHalfInfo.delete(date, amPm);
    }
  }

  /// 有給取得
  /// 半休の場合は amPm を指定すること
  /// 有効期間外の場合は設定しない
  bool acquisitionVacation({
      required final DateTime date,
      final String? eventId,
      final AmPm? amPm,
      final String reason = ''}) {

    // 有効期間内か
    if (!isValidDay(date)) {
      log('$acquisitionVacation\n全休取得失敗 (有効期間外を取得しようとしています '
          '(actual: $date, expected: $givenDate ~ $lapseDate))');
      return false;
    }
    // GoogleカレンダーイベントIDの保存
    return amPm == null
        ? _acquisitionDay(date: date, reason: reason)
        : _acquisitionHalf(date: date, amPm: amPm, reason: reason);
  }

  /// 有給取得(全休)
  /// 下記の場合は設定しない
  ///   ・半休に同じ日付のデータがある
  ///   ・残り日数が足りない
  bool _acquisitionDay({required final DateTime date, final String reason = ''}) {
    // 半休の取得情報に取得日が重なるデータがあるか
    final keys = _acquisitionHalfInfo.acquisitionList.keys;
    final guard = Pair(DateTime(0), AmPm.am); // 番兵
    if (keys.firstWhere((key) => key.first == date, orElse: () => guard) != guard) {
      log('${_acquisitionDay.toString()}\n全休取得失敗 (半休に同じ日付のデータが存在します (${date.toString()}))');
      return false;
    }
    // 残り日数が足りるか
    if (remainingDays < 1) {
      log('${_acquisitionDay.toString()}\n全休取得失敗 (残りの有給数が足りません (actual: $remainingDays, expected: 1~))');
      return false;
    }
    return _acquisitionDateInfo.add(date: date, reason: reason);
  }

  /// 半休取得
  /// 下記の場合は設定しない
  ///   ・半休に同じ日付のデータがある
  ///   ・残り日数が足りない
  bool _acquisitionHalf({required final DateTime date, required final AmPm amPm, final String reason = ''}) {
    // 全休の取得情報に取得日が重なるデータがあるか
    if (_acquisitionDateInfo.acquisitionList.keys.contains(date)) {
      log('${_acquisitionHalf.toString()}\n半休取得失敗 (全休に取得日が重なるデータがあります (取得日: ${date.toString()}))');
      return false;
    }
    // 残り日数が足りるか
    if (remainingDays < 0.5) {
      log('${_acquisitionHalf.toString()}\n半休取得失敗 (残り日数が足りません (actual: $remainingDays, expected: 0.5~))');
      return false;
    }
    return _acquisitionHalfInfo.add(date: date, amPm: amPm, reason: reason);
  }

  /// 取得日上書き
  bool updateAcquisitionInfo({
      required final DateTime prevDate, required final DateTime newDate,
      required final AmPm? prevAmPm, required final AmPm? newAmPm,
      final String newReason = ''}) {

    log('${updateAcquisitionInfo.toString()}\n取得データ更新開始');
    // 前回の理由を保持しておく
    final prevReason = (prevAmPm == null)
        ? _acquisitionDateInfo.acquisitionList[prevDate]
        : _acquisitionHalfInfo.acquisitionList[Pair(prevDate, prevAmPm)];
    if (prevReason == null) {
      log('${updateAcquisitionInfo.toString()}\n前回データが見つかりません');
      return false;
    }
    // 前回データ削除
    deleteAcquisitionInfo(prevDate, prevAmPm);
    // 新しいデータを追加
    final isSuccess = (newAmPm == null)
        ? _acquisitionDay(date: newDate, reason: newReason)
        : _acquisitionHalf(date: newDate, amPm: newAmPm, reason: newReason);
    if (!isSuccess) {
      // 設定できなかった場合は元の設定に戻す
      log('$updateAcquisitionInfo\n取得情報の更新失敗 再設定します (取得日: $newDate ($newAmPm))');
      if (prevAmPm == null) {
        _acquisitionDateInfo.add(date: prevDate, reason: prevReason);
      } else {
        _acquisitionHalfInfo.add(date: prevDate, amPm: prevAmPm, reason: prevReason);
      }
      return false;
    }
    log('$updateAcquisitionInfo\n取得データ更新成功 (取得日: $newDate ($newAmPm))');
    return true;
  }

  /// 消化日数取得
  double get acquisitionTotal => _acquisitionDateInfo.acquisitionDays + _acquisitionHalfInfo.acquisitionDays;
  /// 取得日数取得
  int get acquisitionDays => _acquisitionDateInfo.acquisitionDays;
  /// 半休取得日数取得
  int get acquisitionHalfCount => _acquisitionHalfInfo.acquisitionList.length;
  /// 残り日数取得
  double get remainingDays => _givenDaysInfo.givenDays - acquisitionTotal;

  /// 指定した日が有効期間内か
  bool isValidDay(DateTime date) {
    return (_givenDaysInfo.givenDate == date || _givenDaysInfo.givenDate.isBefore(date))
        && date.isBefore(_givenDaysInfo.lapseDate);
  }
}