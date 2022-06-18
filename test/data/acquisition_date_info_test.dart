import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/data/acquisition_one_day_info.dart';

/// AcquisitionDateInfo クラスの単体テスト
void main() {
  test('add', (){
    final info = AcquisitionOneDayInfo();
    final testDate = DateTime(2022, 4, 1);
    const testReason = '有給休暇';
    expect(info.add(date: testDate, reason: testReason), true);
    expect(info.acquisitionList[testDate], testReason);
  });

  test('add_重複', (){
    final info = AcquisitionOneDayInfo();
    final testDate = DateTime(2022, 4, 1);
    const firstReason = '初回';
    info.add(date: testDate, reason: firstReason);
    expect(info.add(date: testDate, reason: '重複'), false);
    expect(info.acquisitionList[testDate], firstReason);
  });

  test('delete', (){
    final info = AcquisitionOneDayInfo();
    final testDate = DateTime(2022, 4, 1);
    const testReason = '消去';
    info.add(date: testDate, reason: testReason);
    expect(info.acquisitionList[testDate], testReason);
    info.delete(testDate);
    expect(info.acquisitionList[testDate], null);
  });
}