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

  AcquisitionHoursTest.compareTo(
      preparation: today,
      titleToInputAndExpected: {
        '午前休との比較'   : Tuple2(AcquisitionHalf(date: today, amPm: AmPm.am),  1),
        '午後休との比較'   : Tuple2(AcquisitionHalf(date: today, amPm: AmPm.pm), -1),
        '半休以外との比較' : Tuple2(StubAcquisition(date: today),                 0),
      });
}

/// AcquisitionHoursの単体テスト
class AcquisitionHoursTest {
  /// AcquisitionHours.compareToのテスト
  static void compareTo({required Date preparation, required Map<String, Tuple2<Acquisition, int>> titleToInputAndExpected}) {
    titleToInputAndExpected.forEach((title, inputAndExpected) {
      test('AcquisitionHours ($title)', () {
        final acquisition = AcquisitionHours(date: preparation, hours: 1);
        expect(acquisition.compareTo(inputAndExpected.item1), inputAndExpected.item2);
      });
    });
  }
}