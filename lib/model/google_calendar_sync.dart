import 'package:uuid/uuid.dart';

import '../repository/google_calendar_repository.dart';
import '../repository/repository.dart';
import '../utility/api/google_calendar.dart';
import 'acquisition.dart';
import 'calendar_sync.dart';
import 'error_code.dart';

/// GoogleCalendar同期機能
class GoogleCalendarSync implements CalendarSync {
  /// リポジトリ
  final Repository _repository;

  /// コンストラクタ
  GoogleCalendarSync({required Repository repository}) : _repository = repository;

  /// タイトル
  String _title(Acquisition acquisition)
      => '有給取得日${acquisition.subTitle() != null ? ' (${acquisition.subTitle()})' : ''}';

  @override
  Future<ErrorCode> acquire(Acquisition acquisition) async {
    final eventId = const Uuid().v4().replaceAll('-', '');
    final isSuccess = await GoogleCalendar.createEvent(
        eventId: eventId,
        date: acquisition.date,
        title: _title(acquisition),
        description: acquisition.description,
    );
    if (!isSuccess) {
      return ErrorCode.syncCalendarFailed;
    }
    final googleCalendarRepository = GoogleCalendarRepository(repository: _repository);
    googleCalendarRepository.writeEventId(acquisition: acquisition, eventId: eventId);
    return ErrorCode.noError;
  }

  @override
  Future<ErrorCode> updateAcquisition({required Acquisition before, required Acquisition after}) async {
    final googleCalendarRepository = GoogleCalendarRepository(repository: _repository);
    final eventId = await googleCalendarRepository.readEventId(acquisition: before);
    if (eventId == null) {
      return acquire(after);
    }
    final isSuccess = await GoogleCalendar.updateEvent(
        eventId: eventId,
        newDate: after.date,
        newTitle: _title(after),
    );
    return isSuccess ? ErrorCode.noError : ErrorCode.syncCalendarFailed;
  }

  @override
  Future<void> delete(Acquisition acquisition) async {
    final googleCalendarRepository = GoogleCalendarRepository(repository: _repository);
    final eventId = await googleCalendarRepository.readEventId(acquisition: acquisition);
    if (eventId == null) {
      return;
    }
    await GoogleCalendar.deleteEvent(eventId);
    googleCalendarRepository.deleteEventId(acquisition: acquisition);
  }
}