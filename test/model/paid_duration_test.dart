import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/model/paid_duration.dart';
import 'package:tuple/tuple.dart';

void main() {
  PaidDurationTest.hours(
      titleToInputAndExpected: {
        '0時間' : const Tuple3(0, 0, 0),
        '繰り下げ' : const Tuple3(2, -9, 7),
        '繰り上げ' : const Tuple3(0, 17, 1),
      });

  PaidDurationTest.days(
      titleToInputAndExpected: {
        '繰り上げ' : const Tuple3(0, 17, 2),
        '繰り下げ' : const Tuple3(2, -15, 0),
      });

  PaidDurationTest.isCover(
      instance: PaidDuration(days: 1.5, hours: 4), // 2日
      titleToInputAndExpected: {
        '同値' : Tuple2(PaidDuration(days: 1.5, hours: 4), true), // 2日
        '繰り上げ' : Tuple2(PaidDuration(days: 1, hours: 9), false), // 2日, 1時間
        '繰り下げ' : Tuple2(PaidDuration(days: 4, hours: -15), false), // 2日, 1時間
      });
}

/// PaidDurationクラスの単体テスト
class PaidDurationTest {
  /// PaidDuration.hoursのテスト
  static void hours({required Map<String, Tuple3<num, int, int>> titleToInputAndExpected}) {
    titleToInputAndExpected.forEach((title, inputAndExpected) {
      test('PaidDuration.hours ($title)', () {
        final instance = PaidDuration(days: inputAndExpected.item1, hours: inputAndExpected.item2);
        expect(instance.hours(), inputAndExpected.item3);
      });
    });
  }

  /// PaidDuration.daysのテスト
  static void days({required Map<String, Tuple3<num, int, num>> titleToInputAndExpected}) {
    titleToInputAndExpected.forEach((title, inputAndExpected) {
      test('PaidDuration.days ($title)', () {
        final instance = PaidDuration(days: inputAndExpected.item1, hours: inputAndExpected.item2);
        expect(instance.days(), inputAndExpected.item3);
      });
    });
  }

  /// PaidDuration.isCoverのテスト
  /// * note: 所定労働時間は8時間で計算
  static void isCover({required PaidDuration instance, required Map<String, Tuple2<PaidDuration, bool>> titleToInputAndExpected}) {
    titleToInputAndExpected.forEach((title, inputAndExpected) {
      test('PaidDuration.isCover ($title)', () {
        expect(instance.isCover(inputAndExpected.item1), inputAndExpected.item2);
      });
    });
  }
}