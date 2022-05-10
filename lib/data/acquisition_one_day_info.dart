import 'dart:developer';

/// 有給取得日データクラス(全休)
class AcquisitionOneDayInfo {
  /// 全休取得データ
  /// key: 取得日
  /// value: 取得理由
  final Map<DateTime, String> _acquisitionDaysInfo = <DateTime, String>{};
  Map<DateTime, String> get acquisitionList => _acquisitionDaysInfo;

  /// 取得日データ追加
  /// 既に存在する場合は設定しない
  bool add({required final DateTime date, final String reason = ''}) {
    if (_acquisitionDaysInfo.containsKey(date)) {
      log('${add.toString()}\n既にデータが存在します (取得日: ${date.toString()})');
      return false;
    }
    log('${add.toString()}\n取得成功 (取得日: ${date.toString()}, 理由: "$reason")');
    _acquisitionDaysInfo[date] = reason;
    return true;
  }

  /// 取得日データを上書きする
  bool upDate({required final DateTime date, final String reason = ''}) {
    if (!_acquisitionDaysInfo.containsKey(date)) {
      log('${upDate.toString()}\n対象データが存在しません');
      return false;
    }
    _acquisitionDaysInfo[date] = reason;
    return true;
  }

  /// 有給取得日数取得
  int get acquisitionDays => _acquisitionDaysInfo.length;

  /// データを消去する
  /// データがない場合はfalse
  bool delete(DateTime date) {
    log('${delete.toString()}\n取得データを削除します (取得日: ${date.toString()})');
    return _acquisitionDaysInfo.remove(date) == null
        ? false
        : true;
  }
}