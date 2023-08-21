/// 各種データ永続化の際のキー一覧を管理するクラス
class Keys {
  /// 付与日数情報
  static const givenDays = 'GivenDaysInfo';
  /// 全休取得情報
  static const acquisitionDay = 'AcquisitionOneDayInfo';
  /// 半休取得情報
  static const acquisitionHalf = 'AcquisitionHalfInfo';
  /// 時間単位取得情報
  static const acquisitionHourly = 'acquisitionHourInfo';
  /// GoogleCalendar同期設定
  static const isSyncGoogleCalendar = 'IsSyncGoogleCalendar';
  /// GoogleCalendarイベントID
  static const googleCalendarEventId = 'GoogleCalendarEventId';
  /// 最新レビュー依頼日時
  static const latestRequestReviewDate = 'LatestRequestReviewDate';
  /// 広告非表示設定
  static const hideAd = "HideAd";
  /// 区切り文字
  static const splitChar = '@&%#';
}