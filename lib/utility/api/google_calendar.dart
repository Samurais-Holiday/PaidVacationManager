import 'dart:developer';

import 'package:googleapis/calendar/v3.dart';
import 'package:paid_vacation_manager/utility/api/google_sign_in_manager.dart';

/// GoogleカレンダーAPI の機能を提供するクラス
class GoogleCalendar {
  /// Googleカレンダーのスコープを表す文字列
  static const calendarScope = CalendarApi.calendarScope;

  /// Googleカレンダーにイベントを作成する
  /// eventIdに指定するIDをUuidで生成する際に、ハイフンを除いておくこと
  static Future<bool> createEvent({
      required final String eventId,
      required final DateTime date,
      required final String title,
      final String description = '',
  }) async {
    // サインイン
    if (!await GoogleSignInManager.signInGoogle(scope: [calendarScope])) {
      return false;
    }
    // Googleサインインで認証済のHTTPクライアントを参照
    final client = await GoogleSignInManager.authenticatedClient;
    if (client == null) {
      log('$createEvent\nイベント登録失敗: HTTP Client is null');
      GoogleSignInManager.disconnect();
      return false;
    }
    // GoogleカレンダーAPIのインスタンスを生成
    final calendarApi = CalendarApi(client);
    // 登録するイベントのインスタンスを生成
    final event = Event(
        id: eventId,
        start: EventDateTime(date: date),
        end: EventDateTime(date: date),
        summary: title,
        description: description,
    );
    // Googleカレンダーへの登録
    await calendarApi.events.insert(event, 'primary').then((value) {
      if (value.status != 'confirmed') {
        log('$createEvent\nイベント登録失敗: CalendarApi.insert is failed (${value.status})');
        return false;
      }
    });
    log('Googleカレンダーにイベント追加成功(ID: $eventId)');
    return true;
  }

  /// 登録してあるイベントを更新する
  static Future<bool> updateEvent({
      required final String eventId,
      required final DateTime newDate,
      required final String newTitle,
      final String description = '',
  }) async {
    // サインイン
    if (!await GoogleSignInManager.signInGoogle(scope: [calendarScope])) {
      return false;
    }
    // Googleサインインで認証済のHTTPクライアントを参照
    final client = await GoogleSignInManager.authenticatedClient;
    if (client == null) {
      log('$createEvent\nイベント登録失敗: HTTP Client is null');
      GoogleSignInManager.disconnect();
      return false;
    }
    // GoogleカレンダーAPIのインスタンスを生成
    final calendarApi = CalendarApi(client);
    // 登録するイベントのインスタンスを生成
    final event = Event(
      id: eventId,
      start: EventDateTime(date: newDate),
      end: EventDateTime(date: newDate),
      summary: newTitle,
      description: description
    );
    // 予定を更新
    await calendarApi.events.update(event, 'primary', eventId).then((value) {
      if (value.status != 'confirmed') {
        log('$updateEvent\nイベント更新失敗: CalendarApi.update is failed (${value.status})');
        return false;
      }
    });
    log('Googleカレンダーのイベント更新成功(ID: $eventId)');
    return true;
  }

  /// 登録してあるイベントを削除する
  static Future<bool> deleteEvent(final String eventId) async {
    // サインイン
    if (!await GoogleSignInManager.signInGoogle(scope: [calendarScope])) {
      return false;
    }
    // Googleサインインで認証済のHTTPクライアントを参照
    final client = await GoogleSignInManager.authenticatedClient;
    if (client == null) {
      log('$createEvent\n予定削除失敗: HTTP Client is null');
      GoogleSignInManager.disconnect();
      return false;
    }
    // GoogleカレンダーAPIのインスタンスを生成
    final calendarApi = CalendarApi(client);
    calendarApi.events.delete('primary', eventId);
    log('$deleteEvent\nカレンダーから予定を削除しました(ID: $eventId)');
    return true;
  }
}