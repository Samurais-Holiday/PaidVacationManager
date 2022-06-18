import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_manager.dart';
import 'package:paid_vacation_manager/page/display_page.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';
import 'package:paid_vacation_manager/utility/api/ad_banner.dart';
import 'package:paid_vacation_manager/utility/api/google_calendar.dart';
import 'package:paid_vacation_manager/config/configure.dart';
import 'package:paid_vacation_manager/utility/date_times.dart';
import 'package:paid_vacation_manager/utility/error_dialog.dart';
import 'package:paid_vacation_manager/utility/information_dialog.dart';
import 'package:paid_vacation_manager/utility/lists.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';
import 'package:uuid/uuid.dart';

/// 有給の取得情報を登録するページ
/// 編集モードのときはinitialDateの指定が必須
class AcquisitionPage extends StatefulWidget {
  const AcquisitionPage({Key? key,
    required this.manager,
    required this.givenDate,
    this.initialDate,
    this.initialAmPm,
    this.initialHours,
    this.initialReason = '',
    this.isEditingMode = false})
        : super(key: key);

  final PaidVacationManager manager;
  final DateTime givenDate;
  final DateTime? initialDate;
  final AmPm? initialAmPm;
  final int? initialHours;
  final String initialReason;
  final bool isEditingMode;

  @override
  State<StatefulWidget> createState() => _AcquisitionPageState();
}

class _AcquisitionPageState extends State<AcquisitionPage> {
  static const double _menuMaxHeight = 450;
  // initializeMember で初期化を行う
  late PaidVacationInfo _editingInfo;
  late TextEditingController _reasonController;
  late int _acquisitionYear;
  late int _acquisitionMonth;
  late int _acquisitionDay;
  var _isOneDay = true;
  var _isHalfDay = false;
  var _amPm = AmPm.am;
  var _isHour = false;
  var _hours = 1;

  @override
  void initState() {
    super.initState();
    // 編集モードの場合、widget.initialDate が非nullableであることを保証する
    if (widget.isEditingMode
        && widget.initialDate == null) {
      Navigator.pop(context);
      return;
    }
    // Formの初期値を設定
    _initializeMember();
  }

  /// メンバ変数を初期化する
  void _initializeMember() {
    final targetInfo = widget.manager.paidVacationInfo(widget.givenDate);
    if (targetInfo == null) {
      Navigator.pop(context);
      return;
    }
    _editingInfo = targetInfo;
    _reasonController = TextEditingController(text: widget.initialReason);
    final now = DateTime.now();
    if (widget.isEditingMode) {
      // 編集モードのときは元の取得情報を初期値に設定
      _acquisitionYear = widget.initialDate!.year;
      _acquisitionMonth = widget.initialDate!.month;
      _acquisitionDay = widget.initialDate!.day;
      if (widget.initialAmPm != null) {
        _amPm = widget.initialAmPm!;
        _isOneDay = false;
        _isHalfDay = true;
        _isHour = false;
      } else if (widget.initialHours != null) {
        _hours = widget.initialHours!;
        _isOneDay = false;
        _isHalfDay = false;
        _isHour = true;
      }
    } else {
      // 追加モードは有効期間内であれば今日、そうでない場合は付与日に設定する
      _acquisitionYear = _editingInfo.isValidDay(now) ? now.year : _editingInfo.givenDate.year;
      _acquisitionMonth = _editingInfo.isValidDay(now) ? now.month : _editingInfo.givenDate.month;
      _acquisitionDay = _editingInfo.isValidDay(now) ? now.day : _editingInfo.givenDate.day;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: widget.isEditingMode ? const Text('取得内容の修正') : const Text('有給の取得'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AdBannerWidget(),
            Container(
              margin: const EdgeInsets.only(left: 10, top: 50, right: 10, bottom: 10),
              child: _dateForm(),
            ),
            _oneDayOrHalfDayButton(),
            if (_isHalfDay || _isHour)
              Container(margin: const EdgeInsets.only(left: 30, right: 30), height: 1.5, color: Colors.black26,),
            if (_isHalfDay)
              _amOrPmButton(),
            if (_isHour)
              _hoursForm(),
            Container(
              margin: const EdgeInsets.only(left: 30, top: 10, right: 30, bottom: 10),
              child: _inputReasonForm(),
            ),
            const AdBannerWidget(),
            Container(
              margin: const EdgeInsets.all(10),
              child: _navigatePageButton(),
            ),
          ],
        ),
      ),

    );
  }

  /// 日付入力フォーム
  Widget _dateForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('取得日: ', style: Theme.of(context).textTheme.headline6,),
        DropdownButton<int>(
          dropdownColor: Theme.of(context).backgroundColor,
          items: Lists.convertNumListToWidgetList(context, Lists.create(_editingInfo.givenDate.year, _editingInfo.lapseDate.year)),
          value: _acquisitionYear,
          style: Theme.of(context).textTheme.headline5,
          underline: Container(height: 2, color: Colors.black45),
          menuMaxHeight: _menuMaxHeight,
          onChanged: (int? newYear) {
            if (newYear == null) {
              return;
            }
            setState(() {
              _acquisitionYear = newYear;
              _invalidGivenDateThenReset();
            });
          },
        ),
        Text('年', style: Theme.of(context).textTheme.subtitle1,),

        DropdownButton<int>(
          dropdownColor: Theme.of(context).backgroundColor,
          items: _acquisitionYear == _editingInfo.givenDate.year
              ? Lists.convertNumListToWidgetList(context, Lists.create(_editingInfo.givenDate.month, 12), 2) // 下限を設定
              : _acquisitionYear == _editingInfo.lapseDate.year
                  ? Lists.convertNumListToWidgetList(context, Lists.create(1, _editingInfo.lapseDate.month), 2) // 上限を設定
                  : Lists.convertNumListToWidgetList(context, Lists.create(1, 12), 2), // その間
          value: _acquisitionMonth,
          style: Theme.of(context).textTheme.headline5,
          underline: Container(height: 2, color: Colors.black45),
          menuMaxHeight: _menuMaxHeight,
          onChanged: (int? newMonth) {
            if (newMonth == null) {
              return;
            }
            setState(() {
              _acquisitionMonth = newMonth;
              _invalidGivenDateThenReset();
            });
          },
        ),
        Text('月', style: Theme.of(context).textTheme.subtitle1,),

        DropdownButton<int>(
          dropdownColor: Theme.of(context).backgroundColor,
          items: _acquisitionYear == _editingInfo.givenDate.year && _acquisitionMonth == _editingInfo.givenDate.month
              ? Lists.convertNumListToWidgetList(context, Lists.create(_editingInfo.givenDate.day, DateTimes.endOfMonth[_acquisitionMonth]!), 2) // 下限を設定
              : _acquisitionYear == _editingInfo.lapseDate.year && _acquisitionMonth == _editingInfo.lapseDate.month
                  ? Lists.convertNumListToWidgetList(context, Lists.create(1, _editingInfo.lapseDate.day), 2) // 上限を設定
                  : Lists.convertNumListToWidgetList(context, Lists.create(1, DateTimes.endOfMonth[_acquisitionMonth]!), 2), // それらの間
          value: _acquisitionDay,
          style: Theme.of(context).textTheme.headline5,
          underline: Container(height: 2, color: Colors.black45),
          menuMaxHeight: _menuMaxHeight,
          onChanged: (int? newDay) {
            if (newDay == null) {
              return;
            }
            setState(() {
              _acquisitionDay = newDay;
              _invalidGivenDateThenReset();
            });
          },
        ),
        Text('日',  style: Theme.of(context).textTheme.subtitle1,),
      ],
    );
  }

  /// 取得日の入力内容をチェックし、有効期間外になる場合は失効日にセットする
  void _invalidGivenDateThenReset() {
    // 取得日が失効日より後になる場合
    if (_editingInfo.lapseDate.isBefore(DateTime(_acquisitionYear, _acquisitionMonth, _acquisitionDay))) {
      _acquisitionYear = _editingInfo.lapseDate.year;
      _acquisitionMonth = _editingInfo.lapseDate.month;
      _acquisitionDay = _editingInfo.lapseDate.day;
    }
  }

  /// 全休/半休/時間 ラジオボタン
  Widget _oneDayOrHalfDayButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            Radio<bool>(
                value: true,
                groupValue: _isOneDay,
                onChanged: (bool? isOneDay) {
                  setState(() {
                    if (isOneDay == null) {
                      return;
                    }
                    _isOneDay = isOneDay;
                    if (isOneDay) {
                      _isHalfDay = false;
                      _isHour = false;
                    }
                  });
                }
            ),
            Text('全休', style: Theme.of(context).textTheme.headline6,),
          ],
        ),
        Row(
          children: [
            Radio<bool>(
                value: true,
                groupValue: _isHalfDay,
                onChanged: (bool? isHalfDay) {
                  setState(() {
                    if (isHalfDay == null) {
                      return;
                    }
                    _isHalfDay = isHalfDay;
                    if (isHalfDay) {
                      _isOneDay = false;
                      _isHour = false;
                    }
                  });
                }
            ),
            Text('半休', style: Theme.of(context).textTheme.headline6,),
          ],
        ),
        Row(
          children: [
            Radio<bool>(
                value: true,
                groupValue: _isHour,
                onChanged: (bool? isHour) {
                  setState(() {
                    if (isHour == null) {
                      return;
                    }
                    _isHour = isHour;
                    if (isHour) {
                      _isOneDay = false;
                      _isHalfDay = false;
                    }
                  });
                }
            ),
            Text('時間', style: Theme.of(context).textTheme.headline6,),
          ],
        )
      ],
    );
  }

  /// 午前/午後 ラジオボタン
  Widget _amOrPmButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
            children: [
              Radio<AmPm>(
                  value: AmPm.am,
                  groupValue: _amPm,
                  onChanged: (AmPm? newAmPm) {
                    setState(() {
                      if (newAmPm == null) {
                        return;
                      }
                      _amPm = newAmPm;
                    });
                  }
              ),
              Text('午前', style: Theme.of(context).textTheme.headline6,),
            ]
        ),
        Row(
          children: [
            Radio<AmPm>(
                value: AmPm.pm,
                groupValue: _amPm,
                onChanged: (AmPm? newAmPm) {
                  setState(() {
                    if (newAmPm == null) {
                      return;
                    }
                    _amPm = newAmPm;
                  });
                }
            ),
            Text('午後', style: Theme.of(context).textTheme.headline6,),
          ],
        ),
      ],
    );
  }

  /// 時間選択ドロップダウン(0~8)
  Widget _hoursForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton<int>(
          dropdownColor: Theme.of(context).backgroundColor,
          items: Lists.convertNumListToWidgetList(context, Lists.create(1, 8)),
          value: _hours,
          style: Theme.of(context).textTheme.headline5,
          underline: Container(height: 2, color: Colors.black45),
          menuMaxHeight: _menuMaxHeight,
          onChanged: (int? newMonth) {
            if (newMonth == null) {
              return;
            }
            setState(() {
              _hours = newMonth;
            });
          },
        ),
        Text(' 時間', style: Theme.of(context).textTheme.subtitle1,),
      ],
    );
  }

  /// 理由入力フォーム
  Widget _inputReasonForm() {
    return TextFormField(
      controller: _reasonController,
      maxLength: 50,
      maxLines: null,
      style: Theme.of(context).textTheme.headline5,
      decoration: InputDecoration(
        label: Text('取得理由', style: Theme.of(context).textTheme.headline6),
      ),
    );
  }

  /// 画面遷移(登録/キャンセル)を行うボタン
  /// note: ユーザビリティを優先するため、
  /// Googleカレンダーへのイベントの登録が完了する前にInfoダイアログを表示する
  Widget _navigatePageButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('キャンセル', style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),),
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(primary: Theme.of(context).errorColor),
        ),
        ElevatedButton(
          child: Text(
            widget.isEditingMode ? '保存' : '登録',
            style: Theme.of(context).textTheme.headline6?.copyWith(color: Colors.white),
          ),
          onPressed: () async {
            var isSuccess = true;
            final newDate = DateTime(_acquisitionYear, _acquisitionMonth, _acquisitionDay);
            final reason = _reasonController.value.text;
            if (widget.isEditingMode) {
              // 編集モード
              isSuccess = _editingInfo.updateAcquisitionInfo(
                  prevDate: widget.initialDate!, newDate: newDate,
                  prevAmPm: widget.initialAmPm, newAmPm: _isHalfDay ? _amPm : null,
                  prevHours: widget.initialHours, newHours: _isHour ? _hours : null,
                  newReason: reason);
              if (isSuccess) {
                // 成功したらストレージの内容も更新する
                LocalStorageManager.updateAcquisitionInfo(
                    givenDate: _editingInfo.givenDate,
                    prevDate: widget.initialDate!, newDate: newDate,
                    prevAmPm: widget.initialAmPm, newAmPm: _isHalfDay ? _amPm : null,
                    isPrevIsHour: widget.initialHours != null, newHours: _hours,
                    reason: reason);
                // 同期設定がONの場合は、Googleカレンダーの予定を更新する
                if (Configure.instance.isSyncGoogleCalendar) {
                  // デバイスにイベントIDが保存してある場合はそのIDを使用する
                  final eventId = await LocalStorageManager.readGoogleCalendarEventId(
                      date: widget.initialDate!,
                      amPm: widget.initialAmPm,
                      isHour: widget.initialHours != null);
                  if (eventId != null) {
                    GoogleCalendar.updateEvent(
                        eventId: eventId,
                        newDate: newDate,
                        newTitle: '有給取得日${_isHalfDay
                            ? _amPm == AmPm.am
                                ? '（午前）'
                                : '（午後）'
                            : _isHour
                                ? '($_hours時間)'
                                : ''}',
                        description: reason,
                    );
                    await InformationDialog.show(context: context, info: 'Googleカレンダーのイベントを更新します');
                  } else {
                    // デバイスにIDがない場合はイベントの新規登録をする
                    _createCalendarEventAndStoreId(date: newDate, reason: reason);
                    await InformationDialog.show(context: context, info: 'Googleカレンダーにイベントを登録します');
                  }
                }
              }
            } else {
              // 追加モード
              isSuccess = widget.manager.acquisitionVacation(
                  givenDate: widget.givenDate,
                  acquisitionDate: newDate,
                  amPm: _isHalfDay ? _amPm : null,
                  hours: _isHour ? _hours : null,
                  reason: reason,
              );
              if (isSuccess) {
                // 成功したらストレージにも書き込む
                LocalStorageManager.writeAcquisitionInfo(
                    givenDate: _editingInfo.givenDate,
                    acquisitionDate: newDate,
                    amPm: _isHalfDay ? _amPm : null,
                    hours: _isHour ? _hours : null,
                    reason: reason,
                );
                // 同期設定がしてある場合はGoogleカレンダーに予定を追加する
                if (Configure.instance.isSyncGoogleCalendar) {
                  _createCalendarEventAndStoreId(date: newDate, reason: reason);
                  await InformationDialog.show(context: context, info: 'Googleカレンダーにイベントを登録します');
                }

              }
            }
            // 成功していれば表示画面へ遷移する
            if (isSuccess) {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DisplayPage(
                        manager: widget.manager,
                        givenDateToDisplay: _editingInfo.givenDate,
                      )
                  ),
                  (route) => false);
            } else {
              ErrorDialog.show(
                  context: context,
                  detail: 'その日は有給を取得できません\n\n'
                      '　例) 残りの有給数が足りない\n'
                      '　　  他の取得日と重なる');
            }
          },
        )
      ],
    );
  }

  /// Googleカレンダーへイベントの登録及び、デバイスにイベントIDを保存する
  Future _createCalendarEventAndStoreId({
      required final DateTime date,
      final String reason = '',
  }) async {
    final eventId = const Uuid().v4().replaceAll('-', ''); // Googleカレンダーへの登録に必要
    await GoogleCalendar.createEvent(
      eventId: eventId,
      date: date,
      title: '有給取得日${_isHalfDay
          ? _amPm == AmPm.am
              ? '（午前）'
              : '（午後）'
          : _isHour
              ? '($_hours時間)'
              : ''}',
      description: reason,
    ).then((value) async {
      if (value) {
        // 成功したらストレージにイベントIDを保存する
        LocalStorageManager.writeGoogleCalendarEventId(
            eventId: eventId,
            date: date,
            amPm: _isHalfDay ? _amPm : null,
            isHour: _isHour);
      } else {
        log('Googleカレンダーに予定の追加失敗(ID: $eventId)');
      }
    });
  }
}