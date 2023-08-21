import '../repository/repository.dart';
import '../repository/settings_repository.dart';
import 'acquisition.dart';
import 'calendar_sync.dart';
import 'error_code.dart';
import 'google_calendar_sync.dart';
import 'paid_vacation.dart';

/// 設定値管理クラス
class Settings {
  /// リポジトリ
  final Repository _repository;
  /// 所定労働時間
  final num _workingHours;
  /// 広告非表示設定
  bool _hideAd;
  /// 前回のレビュー依頼日
  DateTime? _latestReviewRequest;
  /// カレンダー同期機能
  final Map<_CalendarAppType, CalendarSync> _calendarSync;

  /// コンストラクタ
  Settings({required Repository repository})
      : _repository = repository,
        _workingHours = 8,
        _hideAd = false,
        _calendarSync = {};

  /// 読み込み
  Future<void> load() async {
    final settingsRepository = SettingsRepository(repository: _repository);
    _hideAd = await settingsRepository.readHideAd();
    _latestReviewRequest = await settingsRepository.readLatestReviewRequest();
    if (await settingsRepository.readIsSyncGoogleCalendar()) {
      _calendarSync[_CalendarAppType.google] = GoogleCalendarSync(repository: _repository);
    }
  }

  /// 所定労働時間
  num get workingHours => _workingHours;

  /// 広告非表示設定取得
  bool get hideAd => _hideAd;

  /// 広告非表示設定設定
  set hideAd(bool hide) {
    final settingsRepository = SettingsRepository(repository: _repository);
    settingsRepository.writeHideAd(hide);
    _hideAd = hide;
  }

  /// GoogleCalendar同期設定取得
  bool get isSyncGoogleCalendar => _calendarSync.containsKey(_CalendarAppType.google);

  /// GoogleCalendar同期設定設定
  set isSyncGoogleCalendar(bool isSync) {
    if (isSync) {
      _calendarSync[_CalendarAppType.google] = GoogleCalendarSync(repository: _repository);
    } else {
      _calendarSync.remove(_CalendarAppType.google);
    }
    final settingsRepository = SettingsRepository(repository: _repository);
    settingsRepository.writeIsSyncGoogleCalendar(isSync);
  }

  /// 前回のレビュー依頼日
  ///
  /// 一度もリクエストしていない場合はnullを返却
  DateTime? get latestReviewRequest => _latestReviewRequest;

  /// 前回のレビュー依頼日設定
  set latestReviewRequest(DateTime? date) {
    _latestReviewRequest = date;

    final settingsRepository = SettingsRepository(repository: _repository);
    if (date != null) {
      settingsRepository.writeLatestReviewRequest(date);
    } else {
      settingsRepository.deleteLatestReviewRequest();
    }
  }

  /// 有給取得情報追加
  Future<ErrorCode> addAcquisition(Acquisition acquisition) async {
    var returnCode = ErrorCode.noError;
    for (final sync in _calendarSync.values) {
      final result = await sync.acquire(acquisition);
      if (result != ErrorCode.noError) {
        returnCode = result;
      }
    }
    return returnCode;
  }

  /// 有給取得情報更新
  Future<ErrorCode> updateAcquisition({required Acquisition before, required Acquisition after}) async {
    var returnCode = ErrorCode.noError;
    for (final sync in _calendarSync.values) {
      final result = await sync.updateAcquisition(before: before, after: after);
      if (result != ErrorCode.noError) {
        returnCode = result;
      }
    }
    return returnCode;
  }

  /// 有給情報削除
  Future<void> deletePaidVacation(PaidVacation paidVacation) async {
    for (final acquisition in paidVacation.acquisitionList) {
      await deleteAcquisition(acquisition);
    }
  }

  /// 有給取得情報削除
  Future<void> deleteAcquisition(Acquisition acquisition) async {
    for (final sync in _calendarSync.values) {
      await sync.delete(acquisition);
    }
  }
}

/// 外部カレンダーアプリ種別
enum _CalendarAppType {
  google,
}