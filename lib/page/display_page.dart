import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:paid_vacation_manager/enum/am_pm.dart';
import 'package:paid_vacation_manager/page/acquisition_page.dart';
import 'package:paid_vacation_manager/page/add_page.dart';
import 'package:paid_vacation_manager/page/configuration_page.dart';
import 'package:paid_vacation_manager/utility/api/google_calendar.dart';
import 'package:paid_vacation_manager/config/configure.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_manager.dart';
import 'package:paid_vacation_manager/page/editing_page.dart';
import 'package:paid_vacation_manager/utility/api/ad_banner.dart';
import 'package:paid_vacation_manager/utility/api/ad_interstitial.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';
import 'package:paid_vacation_manager/utility/api/url_manager.dart';

/// 有給情報表示ページ
/// givenDateToDisplayを指定することで、最初に表示する有給情報を指定できる
class DisplayPage extends StatefulWidget {
  const DisplayPage({Key? key, required this.manager, this.givenDateToDisplay}) : super(key: key);
  final PaidVacationManager manager;
  final DateTime? givenDateToDisplay;

  @override
  State<StatefulWidget> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  static const _bannerPeriod = 4; // バナーの表示頻度
  late PaidVacationInfo _displayInfo; // 画面に表示する有給情報

  @override
  void initState() {
    super.initState();
    // 最初に画面に表示する有給情報を設定する
    var displayInfo = (widget.givenDateToDisplay == null)
        ? widget.manager.initialDisplayInfo()
        : widget.manager.paidVacationInfo(widget.givenDateToDisplay!);
    if (displayInfo == null) {
      // 表示するデータがない場合には登録ページへ
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AddPage(manager: widget.manager)),
              (route) => false);
      return;
    }
    _displayInfo = displayInfo;
    // 広告を表示
    AdInterstitial.instance.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      drawer: _drawer(),
      appBar: AppBar(
        title: const Text('有給情報'),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 付与日数関係のデータ
            Container(
              margin: const EdgeInsets.all(10),
              child: _showGivenDaysInfo(),
            ),
            // ボタン類
            Container(
              margin: const EdgeInsets.all(10),
              child: _buttons(),
            ),
            Container(height: 2, color: Theme.of(context).primaryColor),
            Flexible(child: _acquisitionList()),
          ],
        ),
      floatingActionButton: _acquisitionButton(),
    );
  }

  /// ドロワー(ハンバーガー押下時)の表示内容
  Widget _drawer() {
    return Drawer(
      backgroundColor: Theme.of(context).primaryColor,
      child: ListView(
        children: [
          ListTile(
              leading: const Icon(Icons.add, color: Colors.white, ),
              title: Text('付与日数の新規追加', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddPage(manager: widget.manager))
                );
              }
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: Text('設定', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConfigurationPage())

              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.white),
            title: Text('このアプリの使い方', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),),
            onTap: UrlManager.launchManual,
          ),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.white),
            title: Text('プライバシーポリシー', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),),
            onTap: UrlManager.launchPolicy,
          ),
        ],
      ),
    );
  }

  /// 付与日数・取得日数関連の表示
  Widget _showGivenDaysInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _validPeriodWidget(),
        Container(
          margin: const EdgeInsets.only(top: 10),
          child: _givenDaysWidget()
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          child: _acquisitionDaysWidget(),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          child: _remainingDaysWidget(),
        ),
        if (widget.manager.acquisitionHours(_displayInfo) != 0)
          Container(
            margin: const EdgeInsets.only(top: 10),
            child: _acquisitionHoursWidget(),
          ),
      ],
    );
  }

  /// 有効期間を表示する
  Widget _validPeriodWidget() {
    return Text(
      '${_displayInfo.givenDate.year}'
          '/${_displayInfo.givenDate.month.toString().padLeft(2, '0')}'
          '/${_displayInfo.givenDate.day.toString().padLeft(2, '0')}'
          ' ~ ${_displayInfo.lapseDate.year}'
          '/${_displayInfo.lapseDate.month.toString().padLeft(2, '0')}'
          '/${_displayInfo.lapseDate.day.toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.headline5,
    );
  }

  /// 付与日数の表示をする
  Widget _givenDaysWidget() {
    return _displayDaysText(_displayInfo.givenDays.days, '付与日数');
  }

  /// 時間単位での取得時間
  Widget _acquisitionHoursWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('※時間単位での取得: ${widget.manager.acquisitionHours(_displayInfo)} 時間'
            ' (最大 ${(5*Configure.instance.hoursPerHalf).toStringAsFixed(1)} 時間まで)',
          style: Theme.of(context).textTheme.subtitle1,)
      ],
    );
  }

  /// 取得日数・取得時間を表示する
  Widget _acquisitionDaysWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _displayDaysText(_displayInfo.acquisitionTotal.days, '取得日数'),
        if (_displayInfo.acquisitionTotal.hours != 0)
          _displayHourText(_displayInfo.acquisitionTotal.hours),
      ],
    );
  }

  /// 残り日数取得
  Widget _remainingDaysWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _displayDaysText(_displayInfo.remainingDays.days, '残り日数'),
        if (_displayInfo.remainingDays.hours != 0)
          _displayHourText(_displayInfo.remainingDays.hours),
      ],
    );
  }

  /// 「<title>: XX日」を表示する
  Widget _displayDaysText(int days, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$title: ', style: Theme.of(context).textTheme.headline6,),
        Text(days.toString().padLeft(2, '  '), style: Theme.of(context).textTheme.headline4,),
        Text(' 日 ', style: Theme.of(context).textTheme.subtitle1,),
      ],
    );
  }

  /// ～「とX.X時間」を表示する
  Widget _displayHourText(num hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('と', style: Theme.of(context).textTheme.subtitle1,),
        Text(' ${hours.toStringAsFixed(1)}', style: Theme.of(context).textTheme.headline4,),
        Text(' 時間 ', style: Theme.of(context).textTheme.subtitle1,),
      ],
    );
  }

  /// 編集・前へ・次へボタン
  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _changeInfoButton(
            label: '前へ',
            info: widget.manager.prevInfo(_displayInfo),
            iconData: Icons.arrow_left),
        _deleteButton(),
        _editingButton(),
        _changeInfoButton(
            label: '次へ',
            info: widget.manager.nextInfo(_displayInfo),
            iconData: Icons.arrow_right),
      ],
    );
  }

  /// 削除ボタン
  Widget _deleteButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _showConfirmationDialog();
      },
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).errorColor,
      ),
      label: const Text(''),
      icon: const Icon(Icons.delete),
    );
  }

  /// 削除確認ダイアログ
  void _showConfirmationDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('以下の情報を削除します', style: TextStyle(color: Theme.of(context).errorColor),),
            content: Text(
                '付与日: ${_displayInfo.givenDate.year}年 ${_displayInfo.givenDate.month}月 ${_displayInfo.givenDate.day}日\n'
                '失効日: ${_displayInfo.lapseDate.year}年 ${_displayInfo.lapseDate.month}月 ${_displayInfo.lapseDate.day}日\n'
                '有給付与日数: ${_displayInfo.givenDays.days}日\n'
                '取得日数: ${_displayInfo.acquisitionTotal.days}日 と ${_displayInfo.remainingDays.hours.toStringAsFixed(1)}時間\n'
                '残り日数: ${_displayInfo.remainingDays.days}日 と ${_displayInfo.remainingDays.hours.toStringAsFixed(1)}時間'
            ),
            actions: [
              TextButton(
                child: Text('キャンセル', style: Theme.of(context).textTheme.headline6!.copyWith(color: Theme.of(context).errorColor),),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('削除', style: Theme.of(context).textTheme.headline5!.copyWith(color: Theme.of(context).primaryColor),),
                onPressed: () async {
                  // 削除
                  widget.manager.delete(givenDate: _displayInfo.givenDate);
                  LocalStorageManager.deletePaidVacationInfo(_displayInfo);
                  if (Configure.instance.isSyncGoogleCalendar) {
                    // Googleカレンダーに登録してあるイベントがあれば削除する
                    _displayInfo.sortedAcquisitionDate().keys.forEach((key) async {
                      // デバイスにイベントIDが保存してあるか参照する
                      final eventId = await LocalStorageManager.readGoogleCalendarEventId(date: key.item1, amPm: key.item2);
                      if (eventId != null) {
                        // Googleカレンダーのイベントを削除
                        GoogleCalendar.deleteEvent(eventId);
                        // デバイス保存していたイベントIDを削除
                        LocalStorageManager.deleteGoogleCalendarEventId(date: key.item1, amPm: key.item2);
                      }
                    });
                  }
                  // 消した後に表示する有給情報を設定
                  var displayInfo = widget.manager.initialDisplayInfo();
                  if (displayInfo == null) {
                    // 表示データがない場合は登録ページへ
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => AddPage(manager: widget.manager)),
                            (route) => false);
                    return;
                  }
                  // 表示データがある場合は更新
                  setState(() {
                    _displayInfo = displayInfo;
                    Navigator.pop(context);
                  });
                },
              )
            ],
          );
        },
    );
  }

  /// 編集ページへ遷移するボタン
  Widget _editingButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (builder) => EditingPage(manager: widget.manager, givenDate: _displayInfo.givenDate,))
      ),
      label: const Text(''),
      icon: const Icon(Icons.edit),
    );
  }

  /// データを変えて表示するボタン
  Widget _changeInfoButton({required String label, required PaidVacationInfo? info, required IconData iconData}) {
    return ElevatedButton.icon(
      onPressed: info == null ? null : () { // データが無ければ無効化する
        setState(() {
          _displayInfo = info;
        });
      },
      label: Text(label,style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),),
      icon: Icon(iconData),

    );
  }

  /// 有給取得ボタン
  Widget _acquisitionButton() {
    return Container(
      margin: const EdgeInsets.all(10),
      width: 80,
      height: 80,
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AcquisitionPage(manager: widget.manager, givenDate: _displayInfo.givenDate,))
          );
        },
        child: Text('休む!', style: Theme.of(context).textTheme.headline6?.copyWith(color: Colors.white),),
      ),
    );
  }

  /// 取得情報のリストを表示する
  /// Columnの中で使用する場合はFlexibleでくくる必要がある
  Widget _acquisitionList() {
    final acquisitionList = _displayInfo.sortedAcquisitionDate();
    return ListView.builder(
      itemCount: acquisitionList.length,
      itemBuilder: (BuildContext context, int index) {
        final DateTime date = acquisitionList.keys.elementAt(index).item1;
        final AmPm? amPm = acquisitionList.keys.elementAt(index).item2;
        final int? hours = acquisitionList.keys.elementAt(index).item3;
        final String reason = acquisitionList.values.elementAt(index);
        return Dismissible( // スライドで削除可能
          key: UniqueKey(),
          background: Container(color: Theme.of(context).errorColor,),
          child: Column(
            children: [
              if (index == 0 || index % _bannerPeriod == 0)
                AdBannerWidget(backgroundColor: Theme.of(context).primaryColor,),
              ListTile(
                title: Text(_createListTitleStr(date: date, amPm: amPm, hours: hours),
                  style: Theme.of(context).textTheme.headline5,),

                subtitle:  Text(reason, style: Theme.of(context).textTheme.subtitle1,),
                onTap: () {
                  // 取得情報の編集ページへ移動
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AcquisitionPage(
                              manager: widget.manager,
                              givenDate: _displayInfo.givenDate,
                              initialDate: date,
                              initialAmPm: amPm,
                              initialReason: reason,
                              initialHours: hours,
                              isEditingMode: true,
                          )
                      )
                  );
                },
              ),
              Container(
                margin: const EdgeInsets.only(right: 10, left: 10),
                height: 2,
                color: Theme.of(context).highlightColor,
              )
            ],
          ),
          onDismissed: (direction) async {
            setState(() {
              widget.manager.deleteAcquisitionInfo(
                  givenDate: _displayInfo.givenDate,
                  acquisitionDate: date,
                  amPm: amPm,
                  isHour: hours != null);
              LocalStorageManager.deleteAcquisitionInfo(
                  givenDate: _displayInfo.givenDate,
                  acquisitionDate: date,
                  amPm: amPm,
                  isHours: hours != null);
            });
            if (Configure.instance.isSyncGoogleCalendar) {
              // Googleカレンダーからも削除する
              final eventId = await LocalStorageManager.readGoogleCalendarEventId(date: date, amPm: amPm, isHour: hours != null);
              if (eventId == null) {
                log('Googleカレンダーイベント削除失敗: デバイスにイベントIDが見つかりませんでした (ID: $eventId)');
                return;
              }
              GoogleCalendar.deleteEvent(eventId);
              LocalStorageManager.deleteGoogleCalendarEventId(date: date, amPm: amPm);
            }
          },
        );
      },
    );
  }

  /// 取得日リストのタイトルの文字列を生成する
  String _createListTitleStr({
      required final DateTime date,
      final AmPm? amPm,
      final int? hours, }) {
    final String dateStr = '${date.year}'
        '/${date.month.toString().padLeft(2, '0')}'
        '/${date.day.toString().padLeft(2, '0')}';
    // 半休の場合
    if (amPm != null) {
      return dateStr + (amPm == AmPm.am ? '  (午前)' : '  (午前)');
    }
    // 時間単位での取得の場合
    else if (hours != null) {
      return dateStr + '  ($hours 時間)';
    }
    // 全休の場合
    else {
      return dateStr;
    }
  }
}