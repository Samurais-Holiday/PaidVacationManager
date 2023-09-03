import 'package:flutter/material.dart';
import 'package:paid_vacation_manager/model/error_code.dart';
import 'package:paid_vacation_manager/utility/api/ad_interstitial.dart';

import '../model/acquisition.dart';
import '../model/date.dart';
import '../model/given_days.dart';
import '../model/paid_duration.dart';
import '../model/paid_vacation.dart';
import '../model/paid_vacation_list.dart';
import '../model/settings.dart';
import '../utility/api/reviewer.dart';
import 'acquisition_single_page.dart';
import 'component/ad_banner.dart';
import 'component/dialogs.dart';
import 'component/dismissible_list_view.dart';
import 'given_days_edit_page.dart';

/// 有給情報表示画面
class PaidVacationSinglePage extends StatefulWidget {
  /// 有給情報一覧
  final PaidVacationList _list;
  /// 表示する有給情報
  final PaidVacation _paidVacation;
  /// 設定
  final Settings _settings;

  /// コンストラクタ
  const PaidVacationSinglePage({required PaidVacationList list, required PaidVacation paidVacation, required Settings settings, Key? key})
      : _list = list, _paidVacation = paidVacation, _settings = settings, super(key: key);

  @override
  State<StatefulWidget> createState() => _PaidVacationSinglePageState();
}

class _PaidVacationSinglePageState extends State<PaidVacationSinglePage> {
  /// 時間単位での最大取得日数
  static const int _maxHourlyDays = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('取得状況'),
        actions: [
          _editButton(),
          _deleteButton(),
        ],
      ),
      body: _body(),
      floatingActionButton: _addButton(),
    );
  }

  /// 付与日数編集ボタン
  Widget _editButton() {
    final acquisitions = widget._paidVacation.acquisitionList;
    final firstDate = acquisitions.isNotEmpty ? acquisitions.first.date : null;
    final lastDate  = acquisitions.isNotEmpty ? acquisitions.last.date  : null;
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GivenDaysEditPage(
              title: '編集',
              before: widget._paidVacation.givenDays,
              firstDate: lastDate != null
                  ? Date(lastDate.year - 2, lastDate.month, lastDate.day)
                  : Date(Date.today().year - 40),
              lastDate: firstDate ?? Date(Date.today().year + 10),
              acceptText: '保存',
              onAccepted: _onGivenDaysEdited,
              settings: widget._settings,
            ))
        );
        setState(() {});
      }
    );
  }

  /// 付与日数編集時処理
  bool _onGivenDaysEdited(GivenDays? before, GivenDays after) {
    if (before == null) {
      return false;
    }
    if (before.start.isNotSame(after.start) && widget._list.at(after.start) != null) {
      Dialogs.showError(context: context, errorCode: ErrorCode.alreadyExists);
      return false;
    }
    final result = widget._paidVacation.setGivenDays(after, validYears: 2);
    if (result != ErrorCode.noError) {
      Dialogs.showError(context: context, errorCode: result);
      return false;
    }
    return true;
  }

  /// 付与日数削除ボタン
  Widget _deleteButton() {
    return IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          Dialogs.showConfirmation(context: context, text: 'この有給を削除します').then((bool pressedOk) {
            if (!pressedOk) {
              return;
            }
            widget._list.delete(widget._paidVacation);
            widget._settings.deletePaidVacation(widget._paidVacation);
            Navigator.pop(context);
          });
        }
    );
  }

  /// ボディ部
  Widget _body() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(10),
          child: _summary(),
        ),
        if (!widget._settings.hideAd)
          const AdBannerWidget(),
        Flexible(child: _acquisitionList()),
      ],
    );
  }

  /// 有給情報概要
  Widget _summary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          child: _period(),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          child: _givenDays(),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          child: _acquisitionDays(),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          child: _remainingDays(),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          child: _acquisitionHourly(),
        ),
      ],
    );
  }

  /// 有効期間
  Widget _period() {
    final givenDate = widget._paidVacation.givenDays.start;
    final endDate = Date(givenDate.year + widget._settings.validYears, givenDate.month, givenDate.day);
    return Text(
      '${givenDate.year}/${givenDate.month}/${givenDate.day} ~ ${endDate.year}/${endDate.month}/${endDate.day}',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  /// 付与日数
  Widget _givenDays() {
    return _daysText(title: '付与日数', days: widget._paidVacation.givenDays.days);
  }

  /// 取得日数
  Widget _acquisitionDays() {
    return _daysText(
        title: '取得日数',
        days: widget._paidVacation.acquisitionDuration.days(widget._settings.workingHours),
        hours: widget._paidVacation.acquisitionDuration.hours(widget._settings.workingHours),
    );
  }

  /// 残り日数
  Widget _remainingDays() {
    final remaining = PaidDuration(days: widget._paidVacation.givenDays.days) - widget._paidVacation.acquisitionDuration;
    return _daysText(
        title: '残り日数',
        days: remaining.days(widget._settings.workingHours),
        hours: remaining.hours(widget._settings.workingHours),
    );
  }

  /// 日数、時間を表示するWidget
  Widget _daysText({required String title, required num days, int? hours}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 20),
          child: Text('$title:', style: Theme.of(context).textTheme.titleLarge,),
        ),
        Container(
          margin: const EdgeInsets.only(right: 10),
          child: Text(days.toStringAsFixed(1).padLeft(4, '  '), style: Theme.of(context).textTheme.headlineMedium,),
        ),
        Container(
          margin: const EdgeInsets.only(right: 20),
          child: Text('日', style: Theme.of(context).textTheme.titleLarge,),
        ),
        if (hours != null && hours != 0)
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: Text('$hours', style: Theme.of(context).textTheme.headlineMedium,),
          ),
        if (hours != null && hours != 0)
          Text('時間', style: Theme.of(context).textTheme.titleLarge,),
      ],
    );
  }

  /// 時間単位での取得時間
  Widget _acquisitionHourly() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget._paidVacation.acquisitionDuration.totalHours != 0)
          Text(
            '※時間単位での取得: ${widget._paidVacation.acquisitionDuration.totalHours} 時間  (最大 ${widget._settings.workingHours * _maxHourlyDays} 時間)',
            style: Theme.of(context).textTheme.titleMedium,
          )
      ]
    );
  }

  /// 取得情報一覧
  Widget _acquisitionList() {
    return DismissibleListView.builder<Acquisition>(
      context: context,
      items: widget._paidVacation.acquisitionList,
      listTileBuilder: (current) {
        return ListTile(
          title: Text(current.title, style: Theme.of(context).textTheme.headlineSmall,),
          subtitle: Text(current.description, style: Theme.of(context).textTheme.titleMedium,),
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AcquisitionSinglePage(
                  title: '編集',
                  before: current,
                  first: widget._paidVacation.givenDays.start,
                  last: Date(widget._paidVacation.givenDays.start.year + 2),
                  settings: widget._settings,
                  acceptText: '保存',
                  onAccepted: _onEdited,
                ))
            );
            setState(() {});
          },
        );
      },
      onDismissed: (acquisition) {
        widget._paidVacation.deleteAcquisition(acquisition);
        widget._settings.deleteAcquisition(acquisition);
        setState(() {});
      }
    );
  }

  /// 有給取得情報 編集時処理
  bool _onEdited(Acquisition? before, Acquisition after) {
    if (before == null) {
      Dialogs.showError(context: context, text: '編集元データの参照に失敗しました').then((_) => Navigator.pop(context));
      return false;
    }

    final result = widget._paidVacation.updateAcquisition(
        before: before,
        after: after,
        workingHours: widget._settings.workingHours,
        validYears: 2
    );
    if (result != ErrorCode.noError) {
      Dialogs.showError(context: context, errorCode: result);
      return false;
    }
    widget._settings.updateAcquisition(before: before, after: after).then((ErrorCode result) {
      if (result != ErrorCode.noError) {
        Dialogs.showError(context: context, errorCode: result);
      }
    });
    return true;
  }

  /// 有給取得ボタン
  Widget _addButton() {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('休む!'),
      onPressed: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AcquisitionSinglePage(
              title: '有給取得',
              first: widget._paidVacation.givenDays.start,
              last: Date(widget._paidVacation.givenDays.start.year + 2),
              settings: widget._settings,
              acceptText: '取得',
              onAccepted: _onAcquired,
            ))
        );
        setState(() {});
      },
    );
  }

  /// 有給取得時処理
  bool _onAcquired(Acquisition? before, Acquisition after) {
    final result = widget._paidVacation.addAcquisition(
        entry: after,
        workingHours: widget._settings.workingHours,
        validYears: 2
    );
    if (result != ErrorCode.noError) {
      Dialogs.showError(context: context, errorCode: result);
      return false;
    }
    widget._settings.addAcquisition(after).then((ErrorCode result) {
      if (result != ErrorCode.noError) {
        Dialogs.showError(context: context, errorCode: result);
      }
    });

    // レビュー依頼 or 広告の表示
    if (widget._paidVacation.acquisitionList.length == 5) {
      Reviewer.requestShow(context: context, settings: widget._settings);
    } else {
      AdInterstitial.instance.show();
    }
    return true;
  }
}