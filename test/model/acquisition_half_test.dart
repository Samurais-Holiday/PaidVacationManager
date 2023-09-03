import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/model/acquisition.dart';
import 'package:paid_vacation_manager/model/acquisition_half.dart';
import 'package:paid_vacation_manager/model/acquisition_hours.dart';
import 'package:paid_vacation_manager/model/am_pm.dart';
import 'package:paid_vacation_manager/model/date.dart';
import 'package:tuple/tuple.dart';

import '../stub/stub_acquisition.dart';

void main() {
  final today = Date.today();

  AcquisitionHalfTest.compareTo(
      preparation: today,
      titleToInputAndExpected: {
        'AM/PM: 一致'              : Tuple3(AmPm.am, AcquisitionHalf(date: today, amPm: AmPm.am),  0),
        'AM/PM: 不一致(this=午前)'  : Tuple3(AmPm.am, AcquisitionHalf(date: today, amPm: AmPm.pm), -1),
        'AM/PM: 不一致(this=午後)'  : Tuple3(AmPm.pm, AcquisitionHalf(date: today, amPm: AmPm.am),  1),
        '時間単位との比較(this=午前)' : Tuple3(AmPm.am, AcquisitionHours(date: today, hours: 1),     -1),
        '時間単位との比較(this=午後)' : Tuple3(AmPm.pm, AcquisitionHours(date: today, hours: 1),      1),
        '半休、時間単位以外との比較'   : Tuple3(AmPm.am, StubAcquisition(date: today),                 0),
      });
}

/// AcquisitionHalfの単体テスト
class AcquisitionHalfTest {
  /// Acquisition.compareToのテスト
  static void compareTo({required Date preparation, required Map<String, Tuple3<AmPm, Acquisition, int>> titleToInputAndExpected}) {
    titleToInputAndExpected.forEach((title, inputAndExpected) {
      test('AcquisitionHalf ($title)', () {
        final acquisition = AcquisitionHalf(date: preparation, amPm: inputAndExpected.item1);
        expect(acquisition.compareTo(inputAndExpected.item2), inputAndExpected.item3);
      });
    });
  }
}