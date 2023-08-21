import 'dart:collection';

import '../repository/paid_vacation_repository.dart';
import '../utility/logger.dart';
import 'acquisition.dart';
import 'paid_duration.dart';
import 'date.dart';
import 'error_code.dart';
import 'given_days.dart';

/// 有給情報
class PaidVacation implements Comparable<PaidVacation> {
  /// リポジトリ
  final PaidVacationRepository _repository;
  /// 付与日数情報
  GivenDays _givenDays;
  /// 有給取得情報
  final SplayTreeSet<Acquisition> _acquisitions;

  /// コンストラクタ
  PaidVacation({required PaidVacationRepository repository, required GivenDays givenDays})
      : _repository = repository,
        _givenDays = givenDays,
        _acquisitions = SplayTreeSet<Acquisition>();

  /// 付与日数情報取得
  GivenDays get givenDays => _givenDays;

  /// 付与日数情報設定
  ErrorCode setGivenDays(final GivenDays givenDays, {required int validYears}) {
    if (_isInconsistencyGivenDate(givenDays, validYears)) {
      return ErrorCode.inconsistency;
    }
    if (!PaidDuration(days: givenDays.days).isCover(acquisitionDuration)) {
      return ErrorCode.lackDays;
    }
    _repository.deleteGivenDays(_givenDays);
    _repository.writeGivenDays(givenDays);
    _givenDays = givenDays;
    return ErrorCode.noError;
  }

  /// 付与日設定不可か
  bool _isInconsistencyGivenDate(final GivenDays givenDays, int validYears) {
    if (_acquisitions.isEmpty) {
      return false;
    }
    final border = Date(_acquisitions.last.date.year - validYears).add(const Duration(days: 1));
    return givenDays.start.isBefore(border) || _acquisitions.last.date.isBefore(givenDays.start);
  }

  /// 取得情報一覧
  SplayTreeSet<Acquisition> get acquisitionList => _acquisitions;

  /// 昇順定義
  /// 付与日で判断する
  @override
  int compareTo(PaidVacation other) => _givenDays.start.compareTo(other._givenDays.start);

  /// 有給取得情報追加
  ErrorCode addAcquisition({required Acquisition entry, required num workingHours, required int validYears}) {
    if (_isOutOfPeriod(entry, validYears)) {
      Logger.info('Out of validity period.');
      return ErrorCode.outOfPeriod;
    }
    if (_isInvalidDuration(acquisitionDuration + entry.duration, workingHours)) {
      Logger.info('Not enough days remaining.');
      return ErrorCode.lackDays;
    }
    if (!constructAcquisition(entry)) {
      Logger.info('Acquisition date is overlapped.');
      return ErrorCode.overlap;
    }
    _repository.writeAcquisition(givenDate: _givenDays.start, acquisition: entry);
    return ErrorCode.noError;
  }

  /// 有給取得情報追加
  /// 主に構築時に使用する
  bool constructAcquisition(Acquisition acquisition)
      => _acquisitions.add(acquisition);

  /// 取得日が有効期間外か
  bool _isOutOfPeriod(Acquisition acquisition, int validYears)
      => acquisition.date.isBefore(_givenDays.start)
          || acquisition.date.isAfter(Date(_givenDays.start.year + validYears));

  /// 取得時間が不正か
  bool _isInvalidDuration(PaidDuration target, num workingHours)
      => !PaidDuration(days: _givenDays.days).isCover(target, workingHours);

  /// 有給取得日数取得
  /// 新しく生成したインスタンスを返却する
  PaidDuration get acquisitionDuration {
    PaidDuration total = PaidDuration();
    for (final acquisition in _acquisitions) {
      total.add(acquisition.duration);
    }
    return total;
  }

  /// 有給取得情報更新
  ErrorCode updateAcquisition({
      required Acquisition before,
      required Acquisition after,
      required num workingHours,
      required int validYears,
  }) {
    deleteAcquisition(before);
    final result = addAcquisition(entry: after, workingHours: workingHours, validYears: validYears);
    if (result != ErrorCode.noError) {
      Logger.error('Update acquisition is failed.');
      addAcquisition(entry: before, workingHours: workingHours, validYears: validYears);
      return result;
    }
    return ErrorCode.noError;
  }

  /// 有給取得情報削除
  void deleteAcquisition(Acquisition acquisition) {
    _acquisitions.remove(acquisition);
    _repository.deleteAcquisition(givenDate: _givenDays.start, acquisition: acquisition);
  }
}