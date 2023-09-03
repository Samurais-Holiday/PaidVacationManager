import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/model/acquisition.dart';
import 'package:paid_vacation_manager/model/date.dart';
import 'package:paid_vacation_manager/model/error_code.dart';
import 'package:paid_vacation_manager/model/given_days.dart';
import 'package:paid_vacation_manager/model/paid_duration.dart';
import 'package:paid_vacation_manager/model/paid_vacation.dart';
import 'package:paid_vacation_manager/repository/paid_vacation_repository.dart';
import 'package:tuple/tuple.dart';

import '../stub/stub_repository.dart';
import '../stub/stub_acquisition.dart';

void main() {
  final today = Date.today();
  final twoYearsAgo = Date(today.year-2, today.month, today.day);
  final twoYearsLater = Date(today.year+2, today.month, today.day);
  const int validYears = 2;

  PaidVacationTest.setGivenDays(
      preparation: Tuple2(GivenDays(days: 10, start: today), [ StubAcquisition(date: today) ]),
      titleToInputAndExpected: {
        '付与日: 最新の取得日'         : Tuple3(GivenDays(days: 10, start: today),                                         validYears, ErrorCode.noError),
        '付与日: 最新の取得日+1日'     : Tuple3(GivenDays(days: 10, start: today.add(const Duration(days: 1))),            validYears, ErrorCode.inconsistency),
        '付与日: 最後の取得日-2年'     : Tuple3(GivenDays(days: 10, start: twoYearsAgo),                                   validYears, ErrorCode.inconsistency),
        '付与日: 最後の取得日-2年+1日' : Tuple3(GivenDays(days: 10, start: twoYearsAgo.subtract(const Duration(days: 1))), validYears, ErrorCode.inconsistency),
        '付与日数: 取得日数'          : Tuple3(GivenDays(days:  1, start: today),                                         validYears, ErrorCode.noError),
        '付与日数: 取得日数-1日'       : Tuple3(GivenDays(days:  0, start: today),                                         validYears, ErrorCode.lackDays),
      });

  PaidVacationTest.addAcquisition(
      preparation: Tuple2(GivenDays(days: 10, start: today), [ StubAcquisition(date: today.add(const Duration(days: 1))) ]),
      titleToInputAndExpected: {
        '取得日: 付与日+2年'      : Tuple4(StubAcquisition(date: twoYearsLater),                                    8, validYears, ErrorCode.outOfPeriod),
        '取得日: 付与日+2年-1日'  : Tuple4(StubAcquisition(date: twoYearsLater.subtract(const Duration(days: 1))),  8, validYears, ErrorCode.noError),
        '取得日: 付与日'         : Tuple4(StubAcquisition(date: today),                                            8, validYears, ErrorCode.noError),
        '取得日: 付与日-1日'      : Tuple4(StubAcquisition(date: today.subtract(const Duration(days: 1))),          8, validYears, ErrorCode.outOfPeriod),
        '取得日: 重複'           : Tuple4(StubAcquisition(date: today.add(const Duration(days: 1))),               8, validYears, ErrorCode.overlap),
        '取得期間: 付与日数'      : Tuple4(StubAcquisition(date: today, duration: PaidDuration(days: 9)),           8, validYears, ErrorCode.noError),
        '取得期間: 付与日数+1時間' : Tuple4(StubAcquisition(date: today, duration: PaidDuration(days: 9, hours: 1)), 8, validYears, ErrorCode.lackDays),
      });
}

/// PaidVacationクラスの単体テスト
class PaidVacationTest {
  /// リポジトリ生成
  static PaidVacationRepository _createRepository()
      => PaidVacationRepository(repository: StubRepository());

  /// テスト対象インスタンス生成
  static PaidVacation _createPaidVacation(GivenDays givenDays, List<Acquisition> acquisitions, int validYears) {
    final vacation = PaidVacation(repository: _createRepository(), givenDays: givenDays);
    for (final acquisition in acquisitions) {
      expect(vacation.addAcquisition(entry: acquisition, workingHours: 8, validYears: validYears), ErrorCode.noError);
    }
    return vacation;
  }

  /// PaidVacation.setGivenDaysのテスト
  static void setGivenDays({required Tuple2<GivenDays, List<Acquisition>> preparation, required Map<String, Tuple3<GivenDays, int, ErrorCode>> titleToInputAndExpected}) {
    titleToInputAndExpected.forEach((title, inputAndExpected) {
      test('PaidVacation ($title)', () {
        final vacation = _createPaidVacation(preparation.item1, preparation.item2, inputAndExpected.item2);
        expect(vacation.setGivenDays(inputAndExpected.item1, validYears: inputAndExpected.item2), inputAndExpected.item3);
      });
    });
  }

  /// PaidVacation.addAcquisitionのテスト
  static void addAcquisition({required Tuple2<GivenDays, List<Acquisition>> preparation, required Map<String, Tuple4<Acquisition, num, int, ErrorCode>> titleToInputAndExpected}) {
    titleToInputAndExpected.forEach((title, inputToExpected) {
      test('PaidVacation.addAcquisition ($title)', () {
        final vacation = _createPaidVacation(preparation.item1, preparation.item2, inputToExpected.item3);
        expect(vacation.addAcquisition(entry: inputToExpected.item1, workingHours: inputToExpected.item2, validYears: inputToExpected.item3), inputToExpected.item4);
      });
    });
  }
}