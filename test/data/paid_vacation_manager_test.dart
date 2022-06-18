import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_manager.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';

/// PaidVacationManager クラスの単体テスト
void main() {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final tomorrow = today.add(const Duration(days: 1));
  final lastYear = DateTime(today.year - 1, today.month, today.day);
  final threeYearsAgo = DateTime(today.year-3, today.month, today.day);

  test('add_同一付与日なし', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today);
  });

  test('add_同一付与日あり', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today);
    TestUtility.addAndCheck(false, manager, today);
  });

  test('acquisitionVacation_全休_有効データあり', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today);
    TestUtility.addAndCheck(true, manager, lastYear);
    TestUtility.addAndCheck(true, manager, tomorrow);
    expect(manager.acquisitionVacation(givenDate: lastYear, acquisitionDate: today), true);
    TestUtility.checkAcquisitionDays(1, manager, lastYear);
  });

  test('acquisitionVacation_全休_残り日数なし', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today, 1);
    expect(manager.acquisitionVacation(givenDate: today, acquisitionDate: today), true);
    expect(manager.acquisitionVacation(givenDate: today, acquisitionDate: tomorrow), false);
  });

  test('acquisitionVacation_全休_有効データなし', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, threeYearsAgo);
    expect(manager.acquisitionVacation(givenDate: today, acquisitionDate: today), false);
  });

  test('acquisitionVacation_半休_有効データあり', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today);
    TestUtility.addAndCheck(true, manager, lastYear);
    TestUtility.addAndCheck(true, manager, tomorrow);
    expect(manager.acquisitionVacation(givenDate: lastYear, acquisitionDate: today, amPm: AmPm.am), true);
    TestUtility.checkAcquisitionDays(0.5, manager, lastYear);
  });

  test('acquisitionVacation_半休_有効データなし', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, threeYearsAgo);
    expect(manager.acquisitionVacation(givenDate: today, acquisitionDate: today, amPm: AmPm.am), false);
  });

  test('acquisitionVacation_半休_残り日数なし', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today, 1);
    expect(manager.acquisitionVacation(givenDate: today, acquisitionDate: today, amPm: AmPm.am), true);
    expect(manager.acquisitionVacation(givenDate: today, acquisitionDate: today, amPm: AmPm.pm), true);
    expect(manager.acquisitionVacation(givenDate: today, acquisitionDate: tomorrow, amPm: AmPm.am), false);
  });

  test('remainingDays_指定データあり', () {
    final manager = PaidVacationManager();
    const remainingDays = 10;
    TestUtility.addAndCheck(true, manager, today, remainingDays);
    expect(manager.remainingDays(today), remainingDays);
  });

  test('remainingDays_指定データなし', () {
    final manager = PaidVacationManager();
    expect(manager.remainingDays(today), isNull);
  });

  test('initialDisplayInfo_有給取得あり', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today, 10);
    TestUtility.addAndCheck(true, manager, lastYear, 1);
    manager.acquisitionVacation(givenDate: lastYear, acquisitionDate: today, amPm: AmPm.am); // 午前
    expect(manager.initialDisplayInfo()?.givenDate, lastYear);
    manager.acquisitionVacation(givenDate: today, acquisitionDate: today, amPm: AmPm.pm); // 午後
    expect(manager.initialDisplayInfo()?.givenDate, today);
  });

  test('initialDisplayInfo_有給取得なし', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today);
    TestUtility.addAndCheck(true, manager, lastYear);
    expect(manager.initialDisplayInfo()?.givenDate, lastYear);
  });

  test('initialDisplayInfo_データなし', () {
    final manager = PaidVacationManager();
    expect(manager.initialDisplayInfo(), isNull);
  });

  test('backInfo_データあり', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, lastYear);
    TestUtility.addAndCheck(true, manager, today);
    TestUtility.addAndCheck(true, manager, threeYearsAgo);
    expect(manager.prevInfo(manager.paidVacationInfo(lastYear)!)?.givenDate, threeYearsAgo);
    expect(manager.prevInfo(manager.paidVacationInfo(today)!)?.givenDate, lastYear);
  });

  test('backInfo_データなし', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today);
    expect(manager.prevInfo(manager.paidVacationInfo(today)!), isNull);
  });

  test('nextInfo_データあり', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, lastYear);
    TestUtility.addAndCheck(true, manager, today);
    TestUtility.addAndCheck(true, manager, threeYearsAgo);
    expect(manager.nextInfo(manager.paidVacationInfo(threeYearsAgo)!)?.givenDate, lastYear);
    expect(manager.nextInfo(manager.paidVacationInfo(lastYear)!)?.givenDate, today);
  });

  test('nextInfo_データなし', () {
    final manager = PaidVacationManager();
    TestUtility.addAndCheck(true, manager, today);
    expect(manager.prevInfo(manager.paidVacationInfo(today)!), isNull);
  });
}

class TestUtility {
  static void addAndCheck(bool expected, PaidVacationManager target, DateTime givenDate, [int givenDays = 20]) {
    expect(target.addInfo(PaidVacationInfo(GivenDaysInfo(givenDays, givenDate))), expected);
  }

  static void checkAcquisitionDays(num expectedDays, PaidVacationManager target, DateTime targetInfoGivenDate) {
    final targetInfo = target.paidVacationInfo(targetInfoGivenDate);
    if (targetInfo == null) {
      fail('variable `targetInfo`(${targetInfo.toString()}) is null.');
    }
    expect(targetInfo.acquisitionTotal, expectedDays);
  }
}