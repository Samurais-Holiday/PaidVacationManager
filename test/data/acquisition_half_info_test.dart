import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/data/acquisition_half_info.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';

/// AcquisitionHalfInfo クラスの単体テスト
void main() {
  test('add', () {
    final info = AcquisitionHalfInfo();
    final testDate = DateTime(2022, 4, 1);
    const amReason = '午前休取得';
    const pmReason = '午後休取得';
    expect(info.add(date: testDate, amPm: AmPm.am, reason: amReason), true);
    expect(info.acquisitionList[Pair(testDate, AmPm.am)], amReason);
    expect(info.add(date: testDate, amPm: AmPm.pm, reason: pmReason), true);
    expect(info.acquisitionList[Pair(testDate, AmPm.pm)], pmReason);
  });

  test('add_重複', () {
    final info = AcquisitionHalfInfo();
    final testDate = DateTime(2022, 4, 1);
    const testAmPm = AmPm.am;
    const firstReason = '初回';
    info.add(date: testDate, amPm: testAmPm, reason: firstReason);
    expect(info.add(date: testDate, amPm: testAmPm, reason: '重複'), false);
    expect(info.acquisitionList[Pair(testDate, testAmPm)], firstReason);
  });

  test('delete', () {
    final info = AcquisitionHalfInfo();
    final testDate = DateTime(2022, 4, 1);
    const testAmPm = AmPm.am;
    const testReason = '半休取得';
    info.add(date: testDate, amPm: testAmPm, reason: testReason);
    expect(info.acquisitionList[Pair(testDate, testAmPm)], testReason);
    info.delete(testDate, testAmPm);
    expect(info.acquisitionList[Pair(testDate, testAmPm)], null);
  });
}