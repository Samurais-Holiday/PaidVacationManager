import 'package:paid_vacation_manager/model/acquisition.dart';
import 'package:paid_vacation_manager/model/date.dart';
import 'package:paid_vacation_manager/model/paid_duration.dart';

/// 有給取得情報のスタブ
class StubAcquisition extends Acquisition {
  StubAcquisition({required Date date, PaidDuration? duration, String? description})
      : super(date: date, duration: duration ?? PaidDuration(days: 1), description: description ?? '');
}