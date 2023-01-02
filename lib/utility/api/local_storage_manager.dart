import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_manager.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';
import 'package:paid_vacation_manager/utility/date_times.dart';

/// ローカルストレージへ有給情報の読み書きを行う
/// read, write に対してそれぞれのデータは toString() の文字数に依存している
class LocalStorageManager {
  /// インスタンス生成不可
  LocalStorageManager._internal();

  /// 各情報のキー
  static const _givenDaysInfoKey = 'GivenDaysInfo';
  static const _acquisitionOneDayInfoKey = 'AcquisitionOneDayInfo';
  static const _acquisitionHalfInfoKey = 'AcquisitionHalfInfo';
  static const _acquisitionHourInfoKey = 'acquisitionHourInfo';
  static const _isSyncGoogleCalendarKey = 'IsSyncGoogleCalendar';
  static const _googleCalendarEventIdKey = 'GoogleCalendarEventId';
  static const _latestRequestReviewDateKey = 'LatestRequestReviewDate';

  /// 区切り文字
  static const _splitChar = '@&%#';

  /// 有給データ読込
  /// 登録情報がない場合は`null`
  static Future<PaidVacationManager?> readPaidVacationData() async {
    final storageData = await const FlutterSecureStorage().readAll();
    return storageData.isNotEmpty
        ? _createManagerAndSetAll(storageData)
        : null;
  }

  /// ストレージのデータからPaidVacationManager生成
  static PaidVacationManager _createManagerAndSetAll(Map<String, String> storageData) {
    log('${_createManagerAndSetAll.toString()}\n★★★ストレージ⇒PaidVacationManagerへの変換開始★★★');
    final manager = PaidVacationManager();
    _setPaidVacationInfo(manager: manager, storageData: storageData);
    _setAcquisitionInfo(manager: manager, storageData: storageData);  // attention: _setPaidVacationInfoが先に呼び出されていること
    log('${_createManagerAndSetAll.toString()}\n★★★ストレージ⇒PaidVacationManagerへの変換終了★★★\n');
    return manager;
  }

  /// PaidVacationManagerにPaidVacationInfoを設定する
  /// 引数 manager は out引数
  static void _setPaidVacationInfo({required PaidVacationManager manager, required Map<String, String> storageData}) {
    storageData.forEach((key, value) {
      if (key.startsWith(_givenDaysInfoKey)) {
        final givenDaysInfo = _createGivenDaysInfo(key: key, value: value);
        if (givenDaysInfo != null) {
          manager.addInfo(PaidVacationInfo(givenDaysInfo));
        }
      }
    });
  }

  /// ストレージのデータからGivenDaysInfoを生成する
  /// key: GivenDaysInfo + 付与日, value: 失効日 + 付与日数
  static GivenDaysInfo? _createGivenDaysInfo({required String key, required String value}) {
    // 文字列を分割
    final givenDateStr = key.substring(_givenDaysInfoKey.length);
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
            key: '$_givenDaysInfoKey${info.givenDate}',
            value: '${info.lapseDate}${info.givenDays.days}');

  /// PaidVacationManagerに有給取得情報を設定する
  /// 引数 manager は out引数
  static void _setAcquisitionInfo({required PaidVacationManager manager, required final Map<String, String> storageData}) {
    storageData.forEach((key, value) {
      // 全休取得データの場合
      if (key.startsWith(_acquisitionOneDayInfoKey)) {
         _setAcquisitionOneDay(manager: manager, key: key, value: value);
      }
      // 半休取得データの場合
      else if (key.startsWith(_acquisitionHalfInfoKey)) {
        _setAcquisitionHalf(manager: manager, key: key, value: value);
      }
      // 時間単位取得データの場合
      else if (key.startsWith(_acquisitionHourInfoKey)) {
        _setAcquisitionHourInfo(manager: manager, key: key, value: value);
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
    final givenDateStr = key.substring(_acquisitionOneDayInfoKey.length, key.length - DateTimes.length);
    final acquisitionDateStr = key.substring(_acquisitionOneDayInfoKey.length + DateTimes.length);
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

  /// ストレージのデータからPaidVacationManagerに半休取得情報を設定する
  /// key: AcquisitionHalfInfo + 付与日 + 半休取得日 + AM/PM, value: 取得理由
  static bool _setAcquisitionHalf({required PaidVacationManager manager, required String key, required String value}) {
    // keyを分割
    final givenDateStr = key.substring(
        _acquisitionHalfInfoKey.length, // start
        _acquisitionHalfInfoKey.length + DateTimes.length); // end
    final acquisitionDateStr = key.substring(
        _acquisitionHalfInfoKey.length + DateTimes.length, // start
        key.length - AmPm.am.toString().length);           // end
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

  /// ストレージのデータからPaidVacationManagerに時間単位取得情報を設定する
  /// key: AcquisitionHourInfo + 付与日 + 時間単位有給取得日
  /// value: 取得時間(1~8) + 取得理由
  static bool _setAcquisitionHourInfo({
      required PaidVacationManager manager,
      required final String key,
      required final String value }) {

    // key, valueを分割
    final keys = key.split(_splitChar);
    final values = value.split(_splitChar);
    if (keys.length < 3 || values.length < 2) {
      return false;
    }
    // 文字列をそれぞれの型に変換
    final givenDate = DateTime.tryParse(keys[1]);
    final acquisitionDate = DateTime.tryParse(keys[2]);
    final acquisitionHours = int.tryParse(values[0]);
    if (givenDate == null || acquisitionDate == null || acquisitionHours == null) {
      log('$_setAcquisitionHourInfo\n文字列⇒データ型の変換に失敗しました');
      return false;
    }
    final targetInfo = manager.paidVacationInfo(givenDate);
    return targetInfo != null
        ? targetInfo.acquisitionVacation(date: acquisitionDate, hours: acquisitionHours, reason: values[1])
        : false;
  }

  /// 有給取得情報の書き込み
  /// 半休の時は amPm を指定すること
  /// 時間単位の時は acquisitionHours を指定すること
  static Future writeAcquisitionInfo({
      required final DateTime givenDate,
      required final DateTime acquisitionDate,
      final AmPm? amPm,
      final int? hours,
      final String reason = '', }) async {
    // 全休
    if (amPm == null && hours == null) {
      await _writeAcquisitionOneDay(
          givenDate: givenDate,
          acquisitionDate: acquisitionDate,
          reason: reason);
    }
    // 半休
    else if (amPm != null && hours == null) {
      await _writeAcquisitionHalf(
          givenDate: givenDate,
          acquisitionDate: acquisitionDate,
          amPm: amPm,
          reason: reason);
    }
    // 時間単位
    else if (amPm == null && hours != null) {
      await _writeAcquisitionHour(
          givenDate: givenDate,
          acquisitionDate: acquisitionDate,
          acquisitionHours: hours,
          reason: reason);
    }
    else {
      log('$writeAcquisitionInfo\nWrite failure: Invalid acquisitionType');
    }
  }

  /// 全休取得データを書き込む
  /// key: AcquisitionOneDayInfo + 付与日 + 有給取得日, value: 取得理由
  static Future _writeAcquisitionOneDay({
      required final DateTime givenDate,
      required final DateTime acquisitionDate,
      final String reason = '', })
          => const FlutterSecureStorage().write(
              key: '$_acquisitionOneDayInfoKey$givenDate$acquisitionDate',
              value: reason);

  /// 半休取得情報の書き込み
  /// key: AcquisitionHalfInfo + 付与日 + 半休取得日 + AM/PM, value: 取得理由
  static Future _writeAcquisitionHalf({
      required DateTime givenDate,
      required DateTime acquisitionDate,
      required AmPm amPm,
      String reason = '',})
          => const FlutterSecureStorage().write(
              key: '$_acquisitionHalfInfoKey$givenDate$acquisitionDate$amPm',
              value: reason);

  /// 時間単位有給情報の書き込み
  /// key: AcquisitionHourInfo + 付与日 + 時間単位有給取得日
  /// value: 取得時間(1~8) + 取得理由
  static Future _writeAcquisitionHour({
      required final DateTime givenDate,
      required final DateTime acquisitionDate,
      required final int acquisitionHours,
      required final String reason })
          => const FlutterSecureStorage().write(
              key: '$_acquisitionHourInfoKey$_splitChar$givenDate$_splitChar$acquisitionDate',
              value: '$acquisitionHours$_splitChar$reason');

  /// 有給取得情報の更新
  static Future updateAcquisitionInfo({
      required final DateTime givenDate,
      required final DateTime prevDate, required final DateTime newDate,
      final AmPm? prevAmPm, final AmPm? newAmPm,
      final bool isPrevIsHour = false, final int? newHours,
      final String reason = ''}) async {

    await deleteAcquisitionInfo(
        givenDate: givenDate,
        acquisitionDate: prevDate,
        amPm: prevAmPm,
        isHours: isPrevIsHour);
    await writeAcquisitionInfo(
        givenDate: givenDate,
        acquisitionDate: newDate,
        amPm: newAmPm,
        hours: newHours,
        reason: reason);
  }

  /// 有給取得情報の削除
  static Future deletePaidVacationInfo(PaidVacationInfo info) async {
    await _deleteGivenDaysInfo(givenDate: info.givenDate);
    for (var key in info.sortedAcquisitionDate().keys) {
      await deleteAcquisitionInfo(
          givenDate: info.givenDate,
          acquisitionDate: key.item1,
          amPm: key.item2,
          isHours: key.item3 != null);
    }
  }

  /// GivenDaysInfoを削除
  /// key: GivenDaysInfo + 付与日, value: 失効日 + 付与日数
  static Future _deleteGivenDaysInfo({required DateTime givenDate})
      => const FlutterSecureStorage().delete(
          key: '$_givenDaysInfoKey$givenDate');

  /// 有給取得情報の削除
  static Future deleteAcquisitionInfo({
    required final DateTime givenDate,
    required final DateTime acquisitionDate,
    final AmPm? amPm,
    final bool isHours = false }) async {
    // 全休
    if (amPm == null && !isHours) {
      await _deleteAcquisitionOneDay(givenDate: givenDate, acquisitionDate: acquisitionDate);
    }
    // 半休
    else if (amPm != null && !isHours) {
      await _deleteAcquisitionHalf(givenDate: givenDate, acquisitionDate: acquisitionDate, amPm: amPm);
    }
    // 時間単位
    else if (amPm == null && isHours) {
      await _deleteAcquisitionHour(givenDate: givenDate, acquisitionDate: acquisitionDate);
    }
  }

  /// 全休取得データを消去する
  /// key: AcquisitionOneDayInfo + 付与日 + 有給取得日, value: 取得理由
  static Future _deleteAcquisitionOneDay({
      required final DateTime givenDate,
      required final DateTime acquisitionDate })
          => const FlutterSecureStorage().delete(
              key: '$_acquisitionOneDayInfoKey$givenDate$acquisitionDate');

  /// 半休取得情報の削除
  /// key: AcquisitionHalfInfo + 付与日 + 半休取得日 + AM/PM, value: 取得理由
  static Future _deleteAcquisitionHalf({
      required DateTime givenDate,
      required DateTime acquisitionDate,
      required AmPm amPm,})
          => const FlutterSecureStorage().delete(
              key: '$_acquisitionHalfInfoKey$givenDate$acquisitionDate$amPm');

  /// 時間単位有給情報の削除
  /// key: AcquisitionHourInfo + 付与日 + 時間単位有給取得日
  /// value: 取得時間(1~8) + 取得理由
  static Future _deleteAcquisitionHour({
      required final DateTime givenDate,
      required final DateTime acquisitionDate })
          => const FlutterSecureStorage().delete(
              key: '$_acquisitionHourInfoKey$_splitChar$givenDate$_splitChar$acquisitionDate');

  /// Googleカレンダーとの同期設定を読み込む
  /// 記録がない場合もfalse
  static Future<bool> readIsSyncGoogleCalendar() async {
    final isSync = await const FlutterSecureStorage().read(key: _isSyncGoogleCalendarKey);
    log('IsSync value: $isSync\n');
    return isSync != null && isSync == true.toString();
  }

  /// Googleカレンダーとの同期設定を書き込む
  static Future writeIsSyncGoogleCalendar(bool isSync)
      => const FlutterSecureStorage().write(key: _isSyncGoogleCalendarKey, value: isSync.toString());

  /// GoogleカレンダーイベントIDの読込み
  /// イベントIDが記録されていない場合はnull
  static Future<String?> readGoogleCalendarEventId({
    required final DateTime date,
    final AmPm? amPm,
    final bool isHour = false })
        => const FlutterSecureStorage().read(
            key: '$_googleCalendarEventIdKey$date$amPm${isHour ? '$isHour' : ''}');

  /// GoogleカレンダーイベントIDの書き込み
  static Future writeGoogleCalendarEventId({
    required final String eventId,
    required final DateTime date,
    final AmPm? amPm,
    final bool isHour = false})
        => const FlutterSecureStorage().write(
            key: '$_googleCalendarEventIdKey$date$amPm${isHour ? '$isHour' : ''}',
            value: eventId);

  /// GoogleカレンダーイベントIDの削除
  static Future deleteGoogleCalendarEventId({
    required final DateTime date,
    final AmPm? amPm,
    final bool isHour = false})
        => const FlutterSecureStorage().delete(
            key: '$_googleCalendarEventIdKey$date$amPm${isHour ? '$isHour' : ''}');

  /// レビュー依頼を最後にした日付を書き込む
  static Future<void> writeLatestRequestReviewDate(DateTime date)
      => const FlutterSecureStorage().write(key: _latestRequestReviewDateKey, value: date.toString());

  /// レビュー依頼を最後にした日付を取得
  static Future<DateTime?> readLatestRequestReviewDate() async {
    final String? dateStr = await const FlutterSecureStorage().read(key: _latestRequestReviewDateKey);
    return dateStr != null
        ? DateTime.tryParse(dateStr)
        : null;
  }
}