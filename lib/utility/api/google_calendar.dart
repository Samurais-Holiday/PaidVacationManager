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
      log('Authenticated Client is null');
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
        log('Failed to insert Google Calendar event (${value.status}).');
        return false;
      }
    });
    log('Succeed to insert Google Calendar event.');
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
      log('Authenticated Client is null');
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
        log('Failed to update Google Calendar event (${value.status}).');
        return false;
      }
    });
    log('Succeed to update Google Calendar event.');
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
      log('Authenticated Client is null');
      GoogleSignInManager.disconnect();
      return false;
    }
    // GoogleカレンダーAPIのインスタンスを生成
    final calendarApi = CalendarApi(client);
    calendarApi.events.delete('primary', eventId);
    log('Succeed to remove Google Calendar event.');
    return true;
  }
}