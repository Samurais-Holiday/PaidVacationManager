import 'dart:developer';

import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_time.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';
import 'package:tuple/tuple.dart';

/// 全ての有給データを管理するクラス
class PaidVacationManager {
  /// 各付与データ単位の有給情報のリスト
  final _paidVacationInfoList = <PaidVacationInfo>[];
  /// 指定した付与日の有給情報を取得する
  PaidVacationInfo? paidVacationInfo(DateTime givenDate) {
    for (var current in _paidVacationInfoList) {
      if (current.givenDate == givenDate) {
        return current;
      }
    }
    return null;
  }

  /// 新しく付与された有給情報を追加
  /// 付与日が同じデータがある場合は追加しない
  bool addInfo(PaidVacationInfo info) {
    for (var currentInfo in _paidVacationInfoList) {
      if (currentInfo.givenDate == info.givenDate) {
        return false;
      }
    }
    _paidVacationInfoList.add(info);
    log('${addInfo.toString()}\n付与日数データを追加しました '
        '(有効期間: ${info.givenDate.toString()} ~ ${info.lapseDate.toString()}, 付与日数: ${info.givenDays})');
    return true;
  }

  /// 有給情報を削除する
  /// データがなかった場合false
  bool delete({required DateTime givenDate}) {
    for (var currentInfo in _paidVacationInfoList) {
      if (currentInfo.givenDate == givenDate) {
        _paidVacationInfoList.remove(currentInfo);
        log('データ消しました。givenDays:${currentInfo.givenDate.toString()}'
            'lapseDate: ${currentInfo.lapseDate.toString()}');
        return true;
      }
    }
    log('消すデータがありませんでした。');
    return false;
  }

  /// 付与日数修正
  /// 付与日でアクセス
  bool setGivenDays(final DateTime date, final int days) {
   final info = paidVacationInfo(date);
   return info != null
       ? info.setGivenDays(days)
       : false;
  }

  /// 失効日修正
  /// 付与日でアクセスする
  /// 失敗時false
  bool setLapseDate({required DateTime givenDate, required DateTime value}) {
    final info = paidVacationInfo(givenDate); // 引数も参照で帰ってくるらしい
    if (info == null) {
      log('${setLapseDate.toString()}\n失効日更新失敗 (${value.toString()}');
      return false;
    }
    return info.setLapseDate(value);
  }

  /// 有給を取得する
  /// 半休の場合は amPm を指定すること
  /// 時間単位の場合は hours を指定すること
  /// 他の年度の PaidVacationInfo に重複する取得データがあるかチェックを行う
  bool acquisitionVacation({
      required final DateTime givenDate,
      required final DateTime acquisitionDate,
      final AmPm? amPm,
      final int? hours,
      final String reason = '',}) {
    for (var paidVacationInfo in _paidVacationInfoList) {
      // 設定先の PaidVacationInfo は飛ばす
      if (paidVacationInfo.givenDate == givenDate) {
        continue;
      }
      final keys = paidVacationInfo.sortedAcquisitionDate().keys;
      if (amPm == null && hours == null) {
        // 全休の場合は付与日が同じものがあれば設定失敗
        final guard = Tuple3(DateTime(0), null, null); // 番兵
        if (keys.firstWhere((key) => key.item1 == acquisitionDate, orElse: () => guard) != guard) {
          log('$acquisitionVacation\n取得失敗 (取得日が重複しているデータがあります 取得日: $acquisitionDate)');
          return false;
        }
      } else if (amPm != null) {
        // 半休の場合
        if (keys.contains(Tuple3(acquisitionDate, null, null)) // 全休と重なるか
            || keys.contains(Tuple3(acquisitionDate, amPm, null))) { // 他の半休と重なるか
          log('$acquisitionVacation\n取得失敗 (取得日が重複しているデータがあります 取得日: $acquisitionDate ($amPm))');
          return false;
        }
      } else if (hours != null) {
        // 時間単位の場合は全休があれば設定失敗
        if (keys.contains(Tuple3(acquisitionDate, null, null))) {
          log('$acquisitionVacation\n取得失敗 (取得日が重複しているデータがあります 取得日: $acquisitionDate)');
          return false;
        }
      }
    }
    // 取得先の有給情報を参照
    final targetInfo = paidVacationInfo(givenDate);
    if (targetInfo == null) {
      log('$acquisitionVacation\n取得失敗 (設定先のデータが見つかりませんでした)');
      return false;
    }
    return targetInfo.acquisitionVacation(
        date: acquisitionDate,
        amPm: amPm,
        hours: hours,
        reason: reason);
  }

  /// 有給取得データ削除
  bool deleteAcquisitionInfo({
      required final DateTime givenDate,
      required final DateTime acquisitionDate,
      AmPm? amPm,
      bool isHour = false }) {
    final targetInfo = paidVacationInfo(givenDate);
    if (targetInfo == null) {
      return false;
    }
    return targetInfo.deleteAcquisitionInfo(
        date: acquisitionDate,
        amPm: amPm,
        isHour: isHour);
  }

  /// 指定した期間の時間単位での取得時間を取得
  /// 引数の有給情報の付与日から、次の付与があればその付与日までの取得時間を返却
  /// 次の付与がない場合は、失効日までの取得時間を返却
  int acquisitionHours(PaidVacationInfo info) {
    int returnHours = 0;
    final endDate = nextInfo(info)?.givenDate ?? info.lapseDate;
    for (var element in _paidVacationInfoList) {
      returnHours += element.acquisitionHours(beginDate: info.givenDate, endDate: endDate);
    }
    return returnHours;
  }

  /// 指定したデータの残りの日数を取得
  PaidVacationTime? remainingDays(DateTime givenDate) {
    final targetInfo = paidVacationInfo(givenDate);
    return targetInfo?.remainingDays;
  }

  /// 1つ後ろのデータを取得する
  PaidVacationInfo? prevInfo(PaidVacationInfo info) {
    PaidVacationInfo? backInfo;
    for (var currentInfo in _paidVacationInfoList) {
      if (currentInfo.givenDate.isBefore(info.givenDate)
          && (backInfo == null || backInfo.givenDate.isBefore(currentInfo.givenDate))) {
        backInfo = currentInfo;
      }
    }
    return backInfo;
  }

  /// 1つ先のデータを取得する
  PaidVacationInfo? nextInfo(PaidVacationInfo info) {
    PaidVacationInfo? nextInfo;
    for (var currentInfo in _paidVacationInfoList) {
      if (info.givenDate.isBefore(currentInfo.givenDate)
          && (nextInfo == null || currentInfo.givenDate.isBefore(nextInfo.givenDate))) {
        nextInfo = currentInfo;
      }
    }
    return nextInfo;
  }

  /// 表示画面で最初に表示するデータを取得する
  PaidVacationInfo? initialDisplayInfo() {
    PaidVacationInfo? returnInfo;
    for (var currentInfo in _paidVacationInfoList) {
      // 初めのデータは必ず設定する
      if (returnInfo == null) {
        returnInfo = currentInfo;
        continue;
      }
      // returnInfo: 有給取得していない
      if (returnInfo.acquisitionTotal.isEmpty()) {
        // currentInfo: 有給取得している
        if (currentInfo.acquisitionTotal.isNotEmpty()) {
          returnInfo = currentInfo;
        }
        // currentInfo: 有給取得していない & 付与日が古い
        else if (currentInfo.givenDate.isBefore(returnInfo.givenDate)) {
          returnInfo = currentInfo;
        }
      }
      // returnInfo: 有給取得している
      else {
        // currentInfo: 有給取得している & 付与日が新しい
        if (currentInfo.acquisitionTotal.isNotEmpty()
            && returnInfo.givenDate.isBefore(currentInfo.givenDate)) {
          returnInfo = currentInfo;
        }
      }
    }
    return returnInfo;
  }
}