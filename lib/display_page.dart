import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:paid_vacation_manager/acquisition_page.dart';
import 'package:paid_vacation_manager/add_page.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_manager.dart';
import 'package:paid_vacation_manager/editing_page.dart';
import 'package:paid_vacation_manager/utility/ad_banner.dart';
import 'package:paid_vacation_manager/utility/ad_interstitial.dart';
import 'package:paid_vacation_manager/utility/local_storage_manager.dart';

import 'enum/am_pm.dart';

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
  late PaidVacationInfo? _displayInfo;
  static const _bannerPeriod = 4; // バナーの表示頻度

  @override
  void initState() {
    super.initState();
    // 最初に画面に表示する有給情報を設定する
    _displayInfo = (widget.givenDateToDisplay == null)
        ? widget.manager.initialDisplayInfo()
        : widget.manager.paidVacationInfo(widget.givenDateToDisplay!);
    // ここで_displayInfoの非nullableを保証
    if (_displayInfo == null) {
      // 表示するデータがない場合には登録ページへ
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AddPage(manager: widget.manager)),
              (route) => false);
      return;
    }
    // 広告を表示
    AdInterstitial.instance.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      drawer: Drawer(
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
          ],
        ),
      ),
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

  /// 付与日数データの表示
  Widget _showGivenDaysInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: _validPeriodWidget(),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: _givenDaysWidget()
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: _acquisitionDaysWidget(),
        ),
        _remainingDaysWidget(),
      ],
    );
  }

  /// 有効期間を表示する
  Widget _validPeriodWidget() {
    return Text(
      '${_displayInfo!.givenDate.year}'
          '/${_displayInfo!.givenDate.month.toString().padLeft(2, '0')}'
          '/${_displayInfo!.givenDate.day.toString().padLeft(2, '0')}'
          ' ~ ${_displayInfo!.lapseDate.year}'
          '/${_displayInfo!.lapseDate.month.toString().padLeft(2, '0')}'
          '/${_displayInfo!.lapseDate.day.toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.headline5,
    );
  }

  /// 付与日数（有効期間）の表示をする
  Widget _givenDaysWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('付与日数: ', style: Theme.of(context).textTheme.headline6,),
        Text(_displayInfo!.givenDays.toString(), style: Theme.of(context).textTheme.headline4,),
        Text(' 日  ', style: Theme.of(context).textTheme.subtitle1,),
      ],
    );
  }

  /// 取得日数(全休〇回/半休〇回)を表示する
  Widget _acquisitionDaysWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('取得日数: ', style: Theme.of(context).textTheme.headline6,),
        Text(_displayInfo!.acquisitionTotal.toStringAsFixed(1), style: Theme.of(context).textTheme.headline4,),
        Text(' 日  ', style: Theme.of(context).textTheme.subtitle1,),
        Text('( 全休 ${_displayInfo!.acquisitionDays} 回 / 半休 ${_displayInfo!.acquisitionHalfCount} 回 )', style: Theme.of(context).textTheme.subtitle1,),
      ],
    );
  }

  /// 残り日数取得
  Widget _remainingDaysWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('残り日数: ', style: Theme.of(context).textTheme.headline6,),
        Text(_displayInfo!.remainingDays.toStringAsFixed(1), style: Theme.of(context).textTheme.headline4,),
        Text(' 日', style: Theme.of(context).textTheme.subtitle1,),
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
            info: widget.manager.backInfo(_displayInfo!),
            iconData: Icons.arrow_left),
        _deleteButton(),
        _editingButton(),
        _changeInfoButton(
            label: '次へ',
            info: widget.manager.nextInfo(_displayInfo!),
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
                '付与日: ${_displayInfo!.givenDate.year}年 ${_displayInfo!.givenDate.month}月 ${_displayInfo!.givenDate.day}日\n'
                '失効日: ${_displayInfo!.lapseDate.year}年 ${_displayInfo!.lapseDate.month}月 ${_displayInfo!.lapseDate.day}日\n'
                '有給付与日数: ${_displayInfo!.givenDays}日\n'
                '取得日数: ${_displayInfo!.acquisitionTotal}日\n'
                '残り日数: ${_displayInfo!.remainingDays}日'
            ),
            actions: [
              TextButton(
                child: Text('キャンセル', style: Theme.of(context).textTheme.headline6!.copyWith(color: Theme.of(context).errorColor),),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('削除', style: Theme.of(context).textTheme.headline5!.copyWith(color: Theme.of(context).primaryColor),),
                onPressed: () {
                  // 削除
                  widget.manager.delete(givenDate: _displayInfo!.givenDate);
                  LocalStorageManager.deletePaidVacationInfo(_displayInfo!);
                  // 消した後に表示する有給情報を設定
                  _displayInfo = widget.manager.initialDisplayInfo();
                  if (_displayInfo == null) {
                    // 表示データがない場合は登録ページへ
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => AddPage(manager: widget.manager)),
                            (route) => false);
                    return;
                  }
                  // 表示データがある場合は更新
                  setState(() {
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
              MaterialPageRoute(builder: (builder) => EditingPage(manager: widget.manager, givenDate: _displayInfo!.givenDate,))
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
              MaterialPageRoute(builder: (_) => AcquisitionPage(manager: widget.manager, givenDate: _displayInfo!.givenDate,))
          );
        },
        child: Text('休む!', style: Theme.of(context).textTheme.headline6?.copyWith(color: Colors.white),),
      ),
    );
  }

  /// 取得情報のリストを表示する
  /// Columnの中で使用する場合はFlexibleでくくる必要がある
  Widget _acquisitionList() {
    final acquisitionList = _displayInfo!.sortedAcquisitionList();
    return ListView.builder(
      itemCount: acquisitionList.length,
      itemBuilder: (BuildContext context, int index) {
        final date = acquisitionList.keys.elementAt(index).first;
        final amPm = acquisitionList.keys.elementAt(index).last;
        final reason = acquisitionList.values.elementAt(index);
        return Dismissible( // スライドで削除可能
          key: UniqueKey(),
          background: Container(color: Theme.of(context).errorColor,),
          child: Column(
            children: [
              if (index == 0 || index % _bannerPeriod == 0)
                AdBanner(adSize: AdSize.fullBanner, backgroundColor: Theme.of(context).primaryColor,),
              ListTile(
                title: Text('${date.year}'
                    '/${date.month.toString().padLeft(2, '0')}'
                    '/${date.day.toString().padLeft(2, '0')}'
                    '${amPm == null ? ''
                    : amPm == AmPm.am ? '  (午前)'
                    : '  (午後)'}',
                  style: Theme.of(context).textTheme.headline5,),
                subtitle:  Text(reason, style: Theme.of(context).textTheme.subtitle1,),
                onTap: () {
                  // 取得情報の編集ページへ移動
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AcquisitionPage(
                              manager: widget.manager,
                              givenDate: _displayInfo!.givenDate,
                              initialDate: date,
                              initialAmPm: amPm,
                              initialReason: reason,
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
          onDismissed: (direction) {
            setState(() {
              widget.manager.deleteAcquisitionInfo(date, amPm);
              LocalStorageManager.deleteAcquisitionInfo(
                  givenDate: _displayInfo!.givenDate,
                  acquisitionDate: date,
                  amPm: amPm);
            });
          },
        );
      },
    );
  }
}