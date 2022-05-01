import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';

/// GivenDaysInfo クラスの単体試験を行う
void main() {
  test('コンストラクタ', () {
    const testDays = 10;
    final testDate = DateTime(2022, 4, 1);
    final info = GivenDaysInfo(testDays, testDate);
    expect(info.givenDays, testDays);
    expect(info.givenDate, testDate);
    expect(info.lapseDate, DateTime(testDate.year+2, testDate.month, testDate.day));
  });
}