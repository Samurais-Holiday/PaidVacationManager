import 'dart:collection';

import '../repository/paid_vacation_repository.dart';
import '../repository/repository.dart';
import '../utility/logger.dart';
import 'date.dart';
import 'error_code.dart';
import 'given_days.dart';
import 'paid_vacation.dart';

/// 有給情報一覧
class PaidVacationList {
  /// リポジトリ
  final PaidVacationRepository _repository;
  /// 有給情報一覧
  final SplayTreeSet<PaidVacation> _paidVacations;

  /// コンストラクタ
  PaidVacationList({required Repository repository})
      : _repository = PaidVacationRepository(repository: repository),
        _paidVacations = SplayTreeSet<PaidVacation>();

  /// リスト取得
  List<PaidVacation> toList() => _paidVacations.toList();

  /// 付与日での参照
  PaidVacation? at(Date givenDate) {
    for (final paidVacation in _paidVacations) {
      if (paidVacation.givenDays.start.isSame(givenDate)) {
        return paidVacation;
      }
    }
    return null;
  }

  /// 有給情報追加
  ErrorCode add(final GivenDays givenDays) {
    if (at(givenDays.start) != null) {
      Logger.info('Paid vacation is already exists.');
      return ErrorCode.alreadyExists;
    }
    construct(givenDays);
    _repository.writeGivenDays(givenDays);
    return ErrorCode.noError;
  }

  /// 有給情報追加
  /// 構築時に使用する
  void construct(GivenDays givenDays)
      => _paidVacations.add(PaidVacation(repository: _repository, givenDays: givenDays));

  /// 有給情報削除
  void delete(final PaidVacation paidVacation) {
    _paidVacations.remove(paidVacation);
    _repository.deletePaidVacation(paidVacation);
  }
}