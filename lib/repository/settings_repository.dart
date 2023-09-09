import 'keys.dart';
import 'repository.dart';

/// 各種設定値のデータ永続化を実施するクラス
class SettingsRepository {
  /// リポジトリ
  final Repository _repository;

  /// コンストラクタ
  SettingsRepository({required Repository repository}) : _repository = repository;

  /// 所定労働時間読み込み
  Future<int> readWorkingHours() async {
    final hours = await _repository.read(Keys.workingHours);
    return hours != null
        ? int.tryParse(hours) ?? 8
        : 8;
  }

  /// 所定労働時間書き込み
  Future<void> writeWorkingHours(int hours)
      => _repository.write(key: Keys.workingHours, value: '$hours');

  /// 有効期間読み込み
  Future<int> readValidYears() async {
    final years = await _repository.read(Keys.validYears);
    return years != null
        ? int.tryParse(years) ?? 2
        : 2;
  }

  /// 有効期間書き込み
  Future<void> writeValidYears(int years)
      => _repository.write(key: Keys.validYears, value: '$years');

  /// GoogleCalendar同期設定読み込み
  Future<bool> readIsSyncGoogleCalendar() async {
    final isSync = await _repository.read(Keys.isSyncGoogleCalendar);
    return isSync != null && isSync == true.toString();
  }

  /// GoogleCalendar同期設定書き込み
  Future<void> writeIsSyncGoogleCalendar(bool isSync)
      => _repository.write(key: Keys.isSyncGoogleCalendar, value: isSync.toString());

  /// 広告非表示設定読み込み
  Future<bool> readHideAd() async {
    final hideAd = await _repository.read(Keys.hideAd);
    return hideAd != null && hideAd == true.toString();
  }

  /// 広告非表示設定書き込み
  Future<void> writeHideAd(bool hide)
      => _repository.write(key: Keys.hideAd, value: hide.toString());

  /// 前回のレビュー依頼日読み込み
  Future<DateTime?> readLatestReviewRequest() async {
    final date = await _repository.read('');
    return date != null
        ? DateTime.tryParse(date)
        : null;
  }

  /// 前回のレビュー依頼日書き込み
  Future<void> writeLatestReviewRequest(DateTime date)
      => _repository.write(key: Keys.latestRequestReviewDate, value: date.toString());

  /// 前回のレビュー依頼日削除
  Future<void> deleteLatestReviewRequest()
      => _repository.delete(Keys.latestRequestReviewDate);
}