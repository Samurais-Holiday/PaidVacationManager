import 'package:flutter/material.dart';
import 'package:paid_vacation_manager/view/component/dismissible_list_view.dart';
import 'package:paid_vacation_manager/view/given_days_edit_page.dart';

import '../model/date.dart';
import '../model/error_code.dart';
import '../model/given_days.dart';
import '../model/paid_duration.dart';
import '../model/paid_vacation.dart';
import '../model/paid_vacation_list.dart';
import '../model/settings.dart';
import 'component/ad_banner.dart';
import 'component/dialogs.dart';
import 'component/hamburger_menu.dart';
import 'paid_vacation_single_page.dart';

/// 有給情報のリストを表示するページ
class PaidVacationListPage extends StatefulWidget {
  /// 有給情報一覧
  final PaidVacationList _list;
  /// 設定
  final Settings _settings;

  /// コンストラクタ
  const PaidVacationListPage({required PaidVacationList list, required Settings settings, Key? key})
      : _list = list, _settings = settings, super(key: key);

  @override
  State<StatefulWidget> createState() => PaidVacationListPageState();
}

class PaidVacationListPageState extends State<PaidVacationListPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HamburgerMenu(
        context: context,
        settings: widget._settings,
        onPopped: () => setState(() {}),
      ),
      appBar: AppBar(
        title: const Text('有給一覧'),
      ),
      body: _body(),
      floatingActionButton: _addButton(),
    );
  }

  /// ボディ部
  Widget _body() {
    return Column(
      children: [
        if (!widget._settings.hideAd)
          const AdBannerWidget(),
        Expanded(child: _paidVacationList())
      ],
    );
  }

  /// 有給情報一覧
  Widget _paidVacationList() {
    return DismissibleListView.builder<PaidVacation>(
      context: context,
      items: widget._list.toList(),
      listTileBuilder: (current) {
        final remainingDays = PaidDuration(days: current.givenDays.days) - current.acquisitionDuration;
        return ListTile(
          title: Text(
            '${current.givenDays.start.year}/${current.givenDays.start.month}/${current.givenDays.start.day} ~',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          subtitle: Text(
            '残り ${remainingDays.toLabelText(widget._settings.workingHours)} (全${current.givenDays.days}日)'
          ),
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaidVacationSinglePage(
                    list: widget._list,
                    paidVacation: current,
                    settings: widget._settings
                ))
            );
            setState(() {});
          },
        );
      },
      onDismissed: (dismissed) {
        widget._list.delete(dismissed);
        widget._settings.deletePaidVacation(dismissed);
      },
    );
  }

  /// 有給情報追加ボタン
  Widget _addButton() {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('追加'),
      onPressed: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GivenDaysEditPage(
              title: '有給追加',
              firstDate: Date(Date.today().year - 40),
              lastDate: Date(Date.today().year + 10),
              settings: widget._settings,
              onAccepted: _addPaidVacation,
            ))
        );
        setState(() {});
      },
    );
  }

  /// 有給追加時処理
  bool _addPaidVacation(GivenDays? before, GivenDays after) {
    final result = widget._list.add(after);
    if (result != ErrorCode.noError) {
      Dialogs.showError(context: context, errorCode: result);
      return false;
    }
    return true;
  }
}
