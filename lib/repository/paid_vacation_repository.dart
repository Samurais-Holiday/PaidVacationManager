import '../model/acquisition.dart';
import '../model/acquisition_day.dart';
import '../model/acquisition_half.dart';
import '../model/acquisition_hours.dart';
import '../model/am_pm.dart';
import '../model/date.dart';
import '../model/given_days.dart';
import '../model/paid_vacation.dart';
import '../model/paid_vacation_list.dart';
import '../utility/logger.dart';
import 'keys.dart';
import 'repository.dart';

/// 有給情報のデータ永続化を実施するクラス
class PaidVacationRepository {
  /// リポジトリ
  final Repository _repository;
  /// 有給取得情報書き込み用関数テーブル
  late Map<Type, Future<void> Function(Date, Acquisition)> _acquisitionWriter;
  /// 有給取得情報削除用関数テーブル
  late Map<Type, Future<void> Function(Date, Acquisition)> _acquisitionDeleter;

  /// コンストラクタ
  PaidVacationRepository({required final Repository repository}) : _repository = repository {
    _acquisitionWriter = {
      AcquisitionDay : _writeAcquisitionDay,
      AcquisitionHalf : _writeAcquisitionHalf,
      AcquisitionHours : _writeAcquisitionHours,
    };
    _acquisitionDeleter = {
      AcquisitionDay : _deleteAcquisitionDay,
      AcquisitionHalf : _deleteAcquisitionHalf,
      AcquisitionHours : _deleteAcquisitionHours,
    };
  }

  /// 全件読み込み
  Future<PaidVacationList> readAll() async {
    final keyToValue = await _repository.readAll();
    PaidVacationList givenDaysAll = _readGivenDaysAll(keyToValue);
    return _readAcquisitionAll(givenDaysAll, keyToValue);
  }

  /// 付与日数情報読み込み
  PaidVacationList _readGivenDaysAll(final Map<String, String> keyToValue) {
    PaidVacationList paidVacations = PaidVacationList(repository: _repository);
    keyToValue.forEach((key, value) {
      if (key.startsWith(Keys.givenDays)) {
        final givenDays = _parseGivenDays(key: key, value: value);
        if (givenDays != null) {
          paidVacations.construct(givenDays);
        }
      }
    });
    return paidVacations;
  }

  /// 文字列から付与日数情報へ変換
  /// key: Key + 付与日, value: 失効日 + 付与日数
  /// 失効日は「2年後」固定に変更したため未使用
  GivenDays? _parseGivenDays({required String key, required String value}) {
    final start = DateTime.tryParse(key.substring(Keys.givenDays.length));
    final days = int.tryParse(value.substring(DateTime(0).toString().length));
    if (start == null || days == null) {
      Logger.error('Failed to parse given days.');
      return null;
    }
    return GivenDays(
        days: days,
        start: Date.fromDateTime(start));
  }

  /// 有給取得情報読み込み
  /// 付与日が一致する有給情報へ有給取得情報を設定する
  PaidVacationList _readAcquisitionAll(PaidVacationList paidVacations, Map<String, String> keyToValue) {
    keyToValue.forEach((key, value) {
      if (key.startsWith(Keys.acquisitionDay)) {
        paidVacations = _parseAcquisitionDay(list: paidVacations, key: key, value: value);
      } else if (key.startsWith(Keys.acquisitionHalf)) {
        paidVacations = _parseAcquisitionHalf(list: paidVacations, key: key, value: value);
      } else if (key.startsWith(Keys.acquisitionHourly)) {
        paidVacations = _parseAcquisitionHourly(list: paidVacations, key: key, value: value);
      }
    });
    Logger.info('★★★終了');
    return paidVacations;
  }

  /// 文字列から有給取得情報(全休)へ変換
  /// key: Key + 付与日 + 有給取得日, value: 説明
  PaidVacationList _parseAcquisitionDay({required PaidVacationList list, required String key, required String value}) {
    final givenDate = DateTime.tryParse(key.substring(
        Keys.acquisitionDay.length,
        key.length - DateTime(0).toString().length));
    final acquisitionDate = DateTime.tryParse(key.substring(
        Keys.acquisitionDay.length + DateTime(0).toString().length));
    if (givenDate == null || acquisitionDate == null) {
      Logger.error('Failed to parse acquisition day.');
      return list;
    }

    final paidVacation = list.at(Date.fromDateTime(givenDate));
    if (paidVacation == null) {
      Logger.error('PaidVacation is not found.');
      return list;
    }
    paidVacation.constructAcquisition(AcquisitionDay(
        date: Date.fromDateTime(acquisitionDate),
        description: value
    ));
    return list;
  }

  /// 文字列から有給取得情報(半休)へ変換
  /// key: Key + 付与日 + 有給取得日 + AM/PM, value: 説明
  PaidVacationList _parseAcquisitionHalf({required PaidVacationList list, required String key, required String value}) {
    final givenDate = DateTime.tryParse(key.substring(
        Keys.acquisitionHalf.length,
        Keys.acquisitionHalf.length + DateTime(0).toString().length));
    final acquisitionDate = DateTime.tryParse(key.substring(
        Keys.acquisitionHalf.length + DateTime(0).toString().length,
        key.length - AmPm.am.toString().length));
    final amPm = key.substring(key.length - AmPm.am.toString().length) == AmPm.am.toString()
        ? AmPm.am
        : AmPm.pm;
    if (givenDate == null || acquisitionDate == null) {
      Logger.error('Failed to parse acquisition half.');
      return list;
    }

    final paidVacation = list.at(Date.fromDateTime(givenDate));
    if (paidVacation == null) {
      Logger.error('PaidVacation is not found.');
      return list;
    }
    paidVacation.constructAcquisition(AcquisitionHalf(
        date: Date.fromDateTime(acquisitionDate),
        amPm: amPm,
        description: value
    ));
    return list;
  }

  /// 文字列から有給取得情報(時間単位)へ変換
  /// key: Key + 付与日 + 有給取得日, value: 取得時間 + 説明
  PaidVacationList _parseAcquisitionHourly({required PaidVacationList list, required String key, required String value}) {
    final keys = key.split(Keys.splitChar);
    final values = value.split(Keys.splitChar);
    if (keys.length < 3 || values.length < 2) {
      Logger.error('Failed to split acquisition hourly.');
      return list;
    }
    final givenDate = DateTime.tryParse(keys[1]);
    final acquisitionDate = DateTime.tryParse(keys[2]);
    final hours = int.tryParse(values[0]);
    if (givenDate == null || acquisitionDate == null || hours == null) {
      Logger.error('Failed to parse acquisition hourly.');
      return list;
    }

    final paidVacation = list.at(Date.fromDateTime(givenDate));
    if (paidVacation == null) {
      Logger.error('PaidVacation is not found.');
      return list;
    }
    paidVacation.constructAcquisition(AcquisitionHours(
        date: Date.fromDateTime(acquisitionDate),
        hours: hours,
        description: values[1]
    ));
    return list;
  }

  /// 付与日数情報保存
  /// key: GivenDaysInfo + 付与日, value: 失効日 + 付与日数
  Future<void> writeGivenDays(GivenDays givenDays) {
    final dummyLapse = Date(givenDays.start.year+2, givenDays.start.month, givenDays.start.day);
    return _repository.write(
        key: '${Keys.givenDays}${givenDays.start}',
        value: '$dummyLapse${givenDays.days}');
  }

  /// 有給取得情報保存
  Future<void> writeAcquisition({required Date givenDate, required Acquisition acquisition}) async {
    await _acquisitionWriter[acquisition.runtimeType]?.call(givenDate, acquisition);
  }

  /// 全休保存
  /// key: AcquisitionOneDayInfo + 付与日 + 有給取得日, value: 取得理由
  Future<void> _writeAcquisitionDay(Date givenDate, Acquisition acquisition)
      => _repository.write(
          key: '${Keys.acquisitionDay}$givenDate${acquisition.date}',
          value: acquisition.description);

  /// 半休保存
  /// key: AcquisitionHalfInfo + 付与日 + 半休取得日 + AM/PM, value: 取得理由
  Future<void> _writeAcquisitionHalf(Date givenDate, Acquisition acquisition)
      => _repository.write(
          key: '${Keys.acquisitionHalf}$givenDate${acquisition.date}${(acquisition as AcquisitionHalf).amPm}',
          value: acquisition.description);

  /// 時間単位保存
  /// key: AcquisitionHourInfo + 付与日 + 時間単位有給取得日
  /// value: 取得時間(1~8) + 取得理由
  Future<void> _writeAcquisitionHours(Date givenDate, Acquisition acquisition)
      => _repository.write(
          key: '${Keys.acquisitionHourly}${Keys.splitChar}$givenDate${Keys.splitChar}${acquisition.date}',
          value: '${acquisition.duration.hours()}${Keys.splitChar}${acquisition.description}');

  /// 有給取得情報更新
  Future<void> updateAcquisition({required Date givenDate, required Acquisition before, required Acquisition after}) async {
    await deleteAcquisition(givenDate: givenDate, acquisition: before);
    await writeAcquisition(givenDate: givenDate, acquisition: after);
  }

  /// 有給情報削除
  Future<void> deletePaidVacation(PaidVacation vacation) async {
    await deleteGivenDays(vacation.givenDays);
    for (var acquisition in vacation.acquisitionList) {
      await deleteAcquisition(givenDate: vacation.givenDays.start, acquisition: acquisition);
    }
  }

  /// 付与日数情報削除
  /// key: GivenDaysInfo + 付与日, value: 失効日 + 付与日数
  Future<void> deleteGivenDays(GivenDays givenDays)
      => _repository.delete('${Keys.givenDays}${givenDays.start}');

  /// 有給取得情報削除
  Future<void> deleteAcquisition({required Date givenDate, required Acquisition acquisition}) async {
    await _acquisitionDeleter[acquisition.runtimeType]?.call(givenDate, acquisition);
  }

  /// 全休削除
  /// key: AcquisitionOneDayInfo + 付与日 + 有給取得日, value: 取得理由
  Future<void> _deleteAcquisitionDay(Date givenDate, Acquisition acquisition)
      => _repository.delete('${Keys.acquisitionDay}$givenDate${acquisition.date}');

  /// 半休削除
  /// key: AcquisitionHalfInfo + 付与日 + 半休取得日 + AM/PM, value: 取得理由
  Future<void> _deleteAcquisitionHalf(Date givenDate, Acquisition acquisition)
      => _repository.delete('${Keys.acquisitionHalf}$givenDate${acquisition.date}${(acquisition as AcquisitionHalf).amPm}');

  /// 時間単位削除
  /// key: AcquisitionHourInfo + 付与日 + 時間単位有給取得日
  Future<void> _deleteAcquisitionHours(Date givenDate, Acquisition acquisition)
      => _repository.delete('${Keys.acquisitionHourly}${Keys.splitChar}$givenDate${Keys.splitChar}${acquisition.date}');
}