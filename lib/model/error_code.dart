/// 処理の結果
enum ErrorCode {
  /// 成功
  noError,
  /// 有効期間外
  outOfPeriod,
  /// 既にデータが存在する
  alreadyExists,
  /// 残日数不足
  lackDays,
  /// 取得日重複
  overlap,
  /// データ不整合
  inconsistency,
  /// 設定先が見つからない
  notFound,
  /// カレンダーアプリとの同期に失敗
  syncCalendarFailed,
}