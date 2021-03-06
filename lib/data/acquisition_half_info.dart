import 'dart:developer';

import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:paid_vacation_manager/config/configure.dart';
import 'package:paid_vacation_manager/data/paid_vacation_time.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';

/// 有給取得日データクラス(半休)
class AcquisitionHalfInfo {
  /// 半休取得日データ
  /// key: first: 取得日, last: 午前/午後
  /// value: 取得理由
  final Map<Pair<DateTime, AmPm>, String> _acquisitionHalfDays = <Pair<DateTime, AmPm>, String>{};
  Map<Pair<DateTime, AmPm>, String> get acquisitionList => _acquisitionHalfDays;

  /// データ追加
  /// 既に存在する場合は設定しない
  bool add({
      required final DateTime date,
      required final AmPm amPm,
      final String reason = '',}) {

    if (_acquisitionHalfDays.containsKey(Pair(date, amPm))) {
      log('${add.toString()}\n既に取得しています (取得日: ${date.toString()})');
      return false;
    }
    _acquisitionHalfDays[Pair(date, amPm)] = reason;
    log('${add.toString()}\n取得成功 (取得日: ${date.toString()} (${amPm.toString()}), 理由: $reason)');
    return true;
  }

  /// 有給取得日数を取得
  PaidVacationTime get acquisitionDays
      => PaidVacationTime(hours: _acquisitionHalfDays.length * Configure.instance.hoursPerHalf);

  /// データを削除する
  /// データがない場合はfalse
  bool delete(DateTime date, AmPm amPm) {
    log('${delete.toString()}\n取得データを削除します (取得日: ${date.toString()} (${amPm.toString()}))');
    return _acquisitionHalfDays.remove(Pair(date, amPm)) == null
        ? false
        : true;
  }
}