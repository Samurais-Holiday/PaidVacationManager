import '../model/acquisition.dart';
import '../model/acquisition_half.dart';
import '../model/acquisition_hours.dart';
import 'keys.dart';
import 'repository.dart';

/// GoogleCalendar同期用リポジトリ
class GoogleCalendarRepository {
  /// リポジトリ
  final Repository _repository;

  /// コンストラクタ
  GoogleCalendarRepository({required Repository repository}) : _repository = repository;

  /// GoogleCalendarイベントID読み込み
  Future<String?> readEventId({required Acquisition acquisition})
      => _repository.read(_eventIdKey(acquisition));

  /// GoogleCalendarイベントID書き込み
  Future<void> writeEventId({required Acquisition acquisition, required String eventId})
      => _repository.write(key: _eventIdKey(acquisition), value: eventId);

  /// GoogleCalendarイベントID削除
  Future<void> deleteEventId({required Acquisition acquisition})
      => _repository.delete(_eventIdKey(acquisition));

  /// GoogleCalendarイベントIDのKey生成
  String _eventIdKey(Acquisition acquisition) {
    final amPm = acquisition is AcquisitionHalf
        ? acquisition.amPm
        : null;
    final isHourly = acquisition is AcquisitionHours;
    return '${Keys.googleCalendarEventId}${acquisition.date}$amPm${isHourly ? '$isHourly' : ''}';
  }
}