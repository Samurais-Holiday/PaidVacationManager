import 'dart:developer';

import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';

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

  /// 有給情報のリストが空か
  bool get isEmpty => _paidVacationInfoList.isEmpty;

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

  /// 有給上場を削除する
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
  bool setGivenDays(DateTime date, int days) {
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

  /// 指定したタイプの有給を取得する
  /// 半休の場合は amPm を指定すること
  bool acquisitionVacation({required DateTime givenDate, required DateTime acquisitionDate, AmPm? amPm, String reason = ''}) {
    // 何れかの PaidVacationInfo に取得日が重複するのデータがあった場合は設定しない
    for (var paidVacationInfo in _paidVacationInfoList) {
      // 設定先の PaidVacationInfo は飛ばす
      if (paidVacationInfo.givenDate == givenDate) {
        continue;
      }
      final keys = paidVacationInfo.sortedAcquisitionList().keys;
      if (amPm == null) {
        // 全休の場合は付与日が一致で設定失敗
        final guard = Pair(DateTime(0), null); // 番兵
        if (keys.firstWhere((key) => key.first == acquisitionDate, orElse: () => guard) != guard) {
          log('${acquisitionVacation.toString()}\n取得失敗 (取得日が重複しているデータがあります 取得日: ${acquisitionDate.toString()})');
          return false;
        }
      } else {
        // 半休の場合は午前/午後まで一致で設定失敗
        if (keys.contains(Pair(acquisitionDate, amPm))) {
          log('${acquisitionVacation.toString()}\n取得失敗 (取得日が重複しているデータがあります 取得日: ${acquisitionDate.toString()} (${amPm.toString()}))');
          return false;
        }
      }
    }
    final targetInfo = paidVacationInfo(givenDate);
    if (targetInfo == null) {
      log('${acquisitionVacation.toString()}\n取得失敗 (設定先のデータが見つかりませんでした)');
      return false;
    }
    return targetInfo.acquisitionVacation(date: acquisitionDate, amPm: amPm, reason: reason);
  }

  /// 有給取得データ削除
  bool deleteAcquisitionInfo(DateTime date, AmPm? amPm) {
    for (var currentInfo in _paidVacationInfoList) {
      if (currentInfo.deleteAcquisitionInfo(date, amPm)) {
        return true;
      }
    }
    return false;
  }
  /// 指定したデータの残りの日数を取得
  double? remainingDays(DateTime givenDate) {
    final targetInfo = paidVacationInfo(givenDate);
    return targetInfo?.remainingDays;
  }

  /// 1つ後ろのデータを取得する
  PaidVacationInfo? backInfo(PaidVacationInfo info) {
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
          && (nextInfo == null || currentInfo.givenDate.isBefore(info.givenDate))) {
        nextInfo = currentInfo;
      }
    }
    return nextInfo;
  }

  /// 表示画面で最初に表示するデータを取得する
  PaidVacationInfo? initialDisplayInfo() {
    PaidVacationInfo? initialInfo;
    for (var currentInfo in _paidVacationInfoList) {
      // 初めのデータは必ず設定する
      if (initialInfo == null) {
        initialInfo = currentInfo;
        continue;
      }
      // initialInfo: 有給取得していないデータ
      if (initialInfo.acquisitionTotal == 0) {
        // currentInfo: 有給取得しているデータ
        if (0 < currentInfo.acquisitionTotal) {
          initialInfo = currentInfo;
        }
        // currentInfo: 有給取得していない & 古いデータ
        else if (currentInfo.givenDate.isBefore(initialInfo.givenDate)) {
          initialInfo = currentInfo;
        }
      }
      // initialInfo: 有給取得しているデータ
      else {
        // currentInfo: 有給取得している & 新しいデータ
        if (0 < currentInfo.acquisitionTotal
            && initialInfo.givenDate.isBefore(currentInfo.givenDate)) {
          initialInfo = currentInfo;
        }
      }
    }
    return initialInfo;
  }

  /// 最も古い付与日を取得する
  /// データが1つもない場合はnull
  DateTime? beginDate() {
    DateTime? beginDate;
    for (var currentInfo in _paidVacationInfoList) {
      if (beginDate == null
          || currentInfo.givenDate.isBefore(beginDate)) {
        beginDate = currentInfo.givenDate;
      }
    }
    return beginDate;
  }

  /// 最後の失効日を取得
  /// データが1つもない場合はnull
  DateTime? endDate() {
    DateTime? endDate;
    for (var currentInfo in _paidVacationInfoList) {
      if (endDate == null
          || endDate.isBefore(currentInfo.lapseDate)) {
        endDate = currentInfo.lapseDate;
      }
    }
    return endDate;
  }
}