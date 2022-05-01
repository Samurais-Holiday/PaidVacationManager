import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paid_vacation_manager/data/acquisition_one_day_info.dart';
import 'package:paid_vacation_manager/data/acquisition_half_info.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_manager.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';
import 'package:paid_vacation_manager/utility/date_times.dart';

/// ローカルストレージへ有給情報の読み書きを行う
/// read, write に対してそれぞれのデータは toString() の文字数に依存している
class LocalStorageManager {
  /// 有給データ読込
  /// 登録情報がない場合は`null`
  static Future<PaidVacationManager?> readPaidVacationData() async {
    final storageData = await const FlutterSecureStorage().readAll();
    return storageData.isNotEmpty
        ? _createManagerAndSetAll(storageData)
        : null;
  }

  /// ストレージのデータからPaidVacationManager生成
  /// 下記の何れかのデータが記録されている
  static PaidVacationManager _createManagerAndSetAll(Map<String, String> storageData) {
    log('${_createManagerAndSetAll.toString()}\n★★★ストレージ⇒PaidVacationManagerへの変換開始★★★');
    final manager = PaidVacationManager();
    _setPaidVacationInfo(manager: manager, storageData: storageData);
    _setAcquisitionInfo(manager: manager, storageData: storageData);  // attention: _setPaidVacationInfoが先に呼び出されていること
    log('${_createManagerAndSetAll.toString()}\n★★★ストレージ⇒PaidVacationManagerへの変換終了★★★\n');
    return manager;
  }

  /// PaidVacationManagerにPaidVacationInfoを設定する
  static PaidVacationManager _setPaidVacationInfo({required PaidVacationManager manager, required Map<String, String> storageData}) {
    storageData.forEach((key, value) {
      if (key.startsWith(GivenDaysInfo.string)) {
        final givenDaysInfo = _createGivenDaysInfo(key: key, value: value);
        if (givenDaysInfo != null) {
          manager.addInfo(PaidVacationInfo(givenDaysInfo));
        }
      }
    });
    return manager;
  }

  /// ストレージのデータからGivenDaysInfoを生成する
  /// key: GivenDaysInfo + 付与日, value: 失効日 + 付与日数
  static GivenDaysInfo? _createGivenDaysInfo({required String key, required String value}) {
    // 文字列を分割
    final givenDateStr = key.substring(GivenDaysInfo.string.length);
    final lapseDateStr = value.substring(0, DateTimes.length);
    final givenDaysStr = value.substring(DateTimes.length);
    // 文字列をデータ型へ変換
    final givenDate = DateTime.tryParse(givenDateStr);
    final lapseDate = DateTime.tryParse(lapseDateStr);
    final givenDays = int.tryParse(givenDaysStr);
    // 変換に成功していればGivenDaysInfoオブジェクトを生成する
    return !(givenDate == null || lapseDate == null || givenDays == null)
        ? GivenDaysInfo(givenDays, givenDate, lapseDate)
        : null;
  }

  /// GivenDaysInfoを書き込む
  /// key: GivenDaysInfo + 付与日, value: 失効日 + 付与日数
  static Future writeGivenDaysInfo(GivenDaysInfo info)
      => const FlutterSecureStorage().write(
            key: GivenDaysInfo.string + info.givenDate.toString(),
            value: info.lapseDate.toString() + info.givenDays.toString());

  /// GivenDaysInfoを削除
  /// key: GivenDaysInfo + 付与日, value: 失効日 + 付与日数
  static Future _deleteGivenDaysInfo({required DateTime givenDate})
      => const FlutterSecureStorage().delete(
          key: GivenDaysInfo.string + givenDate.toString());

  /// PaidVacationManagerに有給取得情報を設定する
  static void _setAcquisitionInfo({required PaidVacationManager manager, required Map<String, String> storageData}) {
    storageData.forEach((key, value) {
      // 全休取得データの場合
      if (key.startsWith(AcquisitionOneDayInfo.string)) {
         _setAcquisitionOneDay(manager: manager, key: key, value: value);
      }
      // 半休取得データの場合
      else if (key.startsWith(AcquisitionHalfInfo.string)) {
        _setAcquisitionHalf(manager: manager, key: key, value: value);
      }
      else {
        log('${_setAcquisitionInfo.toString()}\n有給取得情報以外のデータです'
            '(key: $key, value: $value)');
      }
    });
  }

  /// ストレージのデータからPaidVacationManagerに全休取得情報を設定する
  /// key: AcquisitionOneDayInfo + 付与日 + 有給取得日, value: 取得理由
  static bool _setAcquisitionOneDay({required PaidVacationManager manager, required String key, required String value}) {
    // keyを分割
    final givenDateStr = key.substring(AcquisitionOneDayInfo.string.length, key.length - DateTimes.length);
    final acquisitionDateStr = key.substring(AcquisitionOneDayInfo.string.length + DateTimes.length);
    // それぞれの型に変換
    final givenDate = DateTime.tryParse(givenDateStr);
    final acquisitionDate = DateTime.tryParse(acquisitionDateStr);
    if (givenDate == null || acquisitionDate == null) {
      log('${_setAcquisitionOneDay.toString()}\n文字列⇒データ型への変換に失敗しました');
      return false;
    }
    // 変換に成功していれば対象のPaidVacationInfoへ設定する
    final targetInfo = manager.paidVacationInfo(givenDate);
    return targetInfo != null
        ? targetInfo.acquisitionVacation(date: acquisitionDate, reason: value)
        : false;
  }

  /// 全休取得データを書き込む
  /// key: AcquisitionOneDayInfo + 付与日 + 有給取得日, value: 取得理由
  static Future _writeAcquisitionOneDay({required DateTime givenDate, required DateTime acquisitionDate, String reason = '', })
      => const FlutterSecureStorage().write(
          key: AcquisitionOneDayInfo.string + givenDate.toString() + acquisitionDate.toString(),
          value: reason);

  /// 全休取得データを消去する
  /// key: AcquisitionOneDayInfo + 付与日 + 有給取得日, value: 取得理由
  static Future _deleteAcquisitionOneDay({required DateTime givenDate, required DateTime acquisitionDate})
      => const FlutterSecureStorage().delete(
          key: AcquisitionOneDayInfo.string + givenDate.toString() + acquisitionDate.toString());

  /// ストレージのデータからPaidVacationManagerに半休取得情報を設定する
  /// key: AcquisitionHalfInfo + 付与日 + 半休取得日 + AM/PM, value: 取得理由
  static bool _setAcquisitionHalf({required PaidVacationManager manager, required String key, required String value}) {
    // keyを分割
    final givenDateStr = key.substring(
        AcquisitionHalfInfo.string.length, // start
        AcquisitionHalfInfo.string.length + DateTimes.length); // end
    final acquisitionDateStr = key.substring(
        AcquisitionHalfInfo.string.length + DateTimes.length, // start
        key.length - AmPm.am.toString().length);              // end
    final amPmStr = key.substring(key.length - AmPm.am.toString().length);
    // それぞれの型に変換
    final givenDate = DateTime.tryParse(givenDateStr);
    final acquisitionDate = DateTime.tryParse(acquisitionDateStr);
    final amPm = (amPmStr == AmPm.am.toString()) ? AmPm.am
        : amPmStr == AmPm.pm.toString() ? AmPm.pm
        : null;
    if (givenDate == null || acquisitionDate == null || amPm == null) {
      log('${_setAcquisitionHalf.toString()}\n文字列⇒データ型への変換に失敗しました');
      return false;
    }
    // 変換に成功していれば対象のPaidVacationInfoへ設定する
    final targetInfo = manager.paidVacationInfo(givenDate);
    return targetInfo != null
        ? targetInfo.acquisitionVacation(date: acquisitionDate, amPm: amPm, reason: value)
        : false;
  }

  /// 半休取得情報の書き込み
  /// key: AcquisitionHalfInfo + 付与日 + 半休取得日 + AM/PM, value: 取得理由
  static Future _writeAcquisitionHalf({
      required DateTime givenDate,
      required DateTime acquisitionDate,
      required AmPm amPm,
      String reason = '',})
          => const FlutterSecureStorage().write(
              key: AcquisitionHalfInfo.string + givenDate.toString() + acquisitionDate.toString() + amPm.toString(),
              value: reason);

  /// 半休取得情報の削除
  /// key: AcquisitionHalfInfo + 付与日 + 半休取得日 + AM/PM, value: 取得理由
  static Future _deleteAcquisitionHalf({
      required DateTime givenDate,
      required DateTime acquisitionDate,
      required AmPm amPm,})
          => const FlutterSecureStorage().delete(
              key: AcquisitionHalfInfo.string + givenDate.toString() + acquisitionDate.toString() + amPm.toString());

  /// 有給取得情報の書き込み
  static Future writeAcquisitionInfo({
      required DateTime givenDate,
      required DateTime acquisitionDate,
      AmPm? amPm,
      String reason = '',})
          => amPm == null
              ? _writeAcquisitionOneDay(givenDate: givenDate, acquisitionDate: acquisitionDate, reason: reason)
              : _writeAcquisitionHalf(givenDate: givenDate, acquisitionDate: acquisitionDate, amPm: amPm, reason: reason);

  /// 有給取得情報の更新
  static Future updateAcquisitionInfo({
      required DateTime givenDate,
      required DateTime prevDate, required DateTime newDate,
      required AmPm? prevAmPm, required AmPm? newAmPm,
      String reason = ''}) async {

    await deleteAcquisitionInfo(
        givenDate: givenDate,
        acquisitionDate: prevDate,
        amPm: prevAmPm);
    await writeAcquisitionInfo(
        givenDate: givenDate,
        acquisitionDate: newDate,
        amPm: newAmPm,
        reason: reason);
  }

  /// 有給取得情報の削除
  static Future deletePaidVacationInfo(PaidVacationInfo info) async {
    await _deleteGivenDaysInfo(givenDate: info.givenDate);
    for (var key in info.sortedAcquisitionList().keys) {
      await deleteAcquisitionInfo(givenDate: info.givenDate, acquisitionDate: key.first, amPm: key.last);
    }
  }

  /// 有給取得情報の削除
  static Future deleteAcquisitionInfo({required DateTime givenDate, required DateTime acquisitionDate, AmPm? amPm})
      => (amPm == null)
          ? _deleteAcquisitionOneDay(givenDate: givenDate, acquisitionDate: acquisitionDate)
          : _deleteAcquisitionHalf(givenDate: givenDate, acquisitionDate: acquisitionDate, amPm: amPm);
}