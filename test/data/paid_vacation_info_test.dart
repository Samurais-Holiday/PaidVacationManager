import 'package:flutter_test/flutter_test.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';

/// PaidVacationInfo クラスの単体テスト
void main() {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final tomorrow = today.add(const Duration(days: 1));

  test('setGivenDays_取得日数と同値', () {
    const firstGivenDays = 2;
    final givenDate =  DateTime(2022, 4, 1);
    final info = PaidVacationInfo(GivenDaysInfo(firstGivenDays,givenDate));
    expect(info.givenDays, firstGivenDays);
    // 1日取得
    info.acquisitionVacation(date: givenDate.add(const Duration(days: 1)), reason: '有給取得');
    // 付与日数再設定
    const secondGivenDays = 1;
    expect(info.setGivenDays(secondGivenDays), true);
    expect(info.givenDays, secondGivenDays);
  });

  test('setGivenDays_取得日数未満', () {
    const firstGivenDays = 2;
    final info = PaidVacationInfo(GivenDaysInfo(firstGivenDays, today));
    expect(info.givenDays, firstGivenDays);
    // 1.5日取得
    info.acquisitionVacation(date: today.add(const Duration(days: 1)));
    info.acquisitionVacation(date: today.add(const Duration(days: 2)), amPm: AmPm.am);
    // 付与日数を1日に設定
    const secondGivenDays = 1;
    expect(info.setGivenDays(secondGivenDays), false);
    expect(info.givenDays, firstGivenDays);
  });

  test('setLapseDate_2年後', () {
    final testGivenDate = DateTime(2022, 4, 1);
    final threeYearsAgo = DateTime(2025, 4, 1);
    final info = PaidVacationInfo(GivenDaysInfo(20, testGivenDate, threeYearsAgo));
    // 2年後に再設定
    expect(info.setLapseDate(DateTime(testGivenDate.year + 2, testGivenDate.month, testGivenDate.day)), true);
  });

  test('setLapseDate_2年未満', () {
    final testGivenDate = DateTime(2022, 4, 1);
    final threeYearsAgo = DateTime(2025, 4, 1);
    final info = PaidVacationInfo(GivenDaysInfo(20, testGivenDate, threeYearsAgo));
    // 2年後 - 1日に再設定
    expect(info.setLapseDate(DateTime(testGivenDate.year + 2, 3, 31)), false);
  });

  test('remainingDays', () {
    const givenDays = 20;
    final givenDate = DateTime(2022, 4, 1);
    final info = PaidVacationInfo(GivenDaysInfo(givenDays, givenDate));
    // 1.5日取得
    info.acquisitionVacation(date: givenDate.add(const Duration(days: 1)));
    info.acquisitionVacation(date: givenDate.add(const Duration(days: 2)), amPm: AmPm.am);
    expect(info.remainingDays, givenDays - 1.5);
  });

  test('acquisitionList', () {
    final info = PaidVacationInfo(GivenDaysInfo(10, today));
    info.acquisitionVacation(date: tomorrow, amPm: AmPm.am, reason: '半休_明日午前');
    info.acquisitionVacation(date: today, reason: '全休_今日');
    info.acquisitionVacation(date: tomorrow, amPm: AmPm.pm, reason: '半休_明日午後');
    final expectedReason = <String>['全休_今日', '半休_明日午前', '半休_明日午後'];
    var i = 0;
    for (var reason in info.sortedAcquisitionDate().values) {
      expect(reason, expectedReason[i]);
      i++;
    }
  });
}