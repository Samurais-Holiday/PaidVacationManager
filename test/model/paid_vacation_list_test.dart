import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/model/date.dart';
import 'package:paid_vacation_manager/model/error_code.dart';
import 'package:paid_vacation_manager/model/given_days.dart';
import 'package:paid_vacation_manager/model/paid_vacation_list.dart';
import 'package:tuple/tuple.dart';

import '../stub/stub_repository.dart';

void main() {
  final today = Date.today();

  PaidVacationListTest.at(
      preparation: [ GivenDays(days: 10, start: today) ],
      titleToInputAndExists: {
        '該当データ有り'       : Tuple2(today,                                   true),
        '該当データ無し(1日後)' : Tuple2(today.add(const Duration(days: 1)),      false),
        '該当データ無し(1日前)' : Tuple2(today.subtract(const Duration(days: 1)), false),
      }
  );

  PaidVacationListTest.add(
      preparation: [ GivenDays(days: 10, start: today) ],
      titleToInputAndExpected: {
        '付与日: 既存の付与日'     : Tuple2(GivenDays(days: 15, start: today),                                   ErrorCode.alreadyExists),
        '付与日: 既存の付与日+1日' : Tuple2(GivenDays(days: 15, start: today.add(const Duration(days: 1))),      ErrorCode.noError),
        '付与日: 既存の付与日-1日' : Tuple2(GivenDays(days: 15, start: today.subtract(const Duration(days: 1))), ErrorCode.noError),
      }
  );
}

/// PaidVacationListの単体テスト
class PaidVacationListTest {
  /// テスト対象インスタンス生成
  static PaidVacationList _createInstance(List<GivenDays> givenDaysList) {
    final list = PaidVacationList(repository: StubRepository());
    for (final givenDays in givenDaysList) {
      list.construct(givenDays);
    }
    return list;
  }

  /// PaidVacation.atのテスト
  static void at({required List<GivenDays> preparation, required Map<String, Tuple2<Date, bool>> titleToInputAndExists}) {
    titleToInputAndExists.forEach((title, inputAndExists) {
      test('PaidVacationList.at ($title)', () {
        final list = _createInstance(preparation);
        expect(list.at(inputAndExists.item1) != null, inputAndExists.item2);
      });
    });
  }

  /// PaidVacation.addのテスト
  static void add({required List<GivenDays> preparation, required Map<String, Tuple2<GivenDays, ErrorCode>> titleToInputAndExpected}) {
    titleToInputAndExpected.forEach((title, inputAndExpected) {
      final list = _createInstance(preparation);
      test('PaidVacationList.add ($title)', () {
        expect(list.add(inputAndExpected.item1), inputAndExpected.item2);
      });
    });
  }
}
