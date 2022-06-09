import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_manager.dart';
import 'package:paid_vacation_manager/page/display_page.dart';
import 'package:paid_vacation_manager/utility/api/ad_banner.dart';
import 'package:paid_vacation_manager/utility/date_times.dart';
import 'package:paid_vacation_manager/utility/error_dialog.dart';
import 'package:paid_vacation_manager/utility/lists.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';

/// 付与内容の編集を行うページ
class EditingPage extends StatefulWidget {
  const EditingPage({Key? key, required this.manager, required this.givenDate}) : super(key: key);
  final PaidVacationManager manager;
  final DateTime givenDate;

  @override
  State<StatefulWidget> createState() => _EditingPageState();
}

class _EditingPageState extends State<EditingPage> {
  static const double _menuMaxHeight = 450;
  late TextEditingController _givenDaysController;
  late int _lapseYear;
  late int _lapseMonth;
  late int _lapseDay;

  @override
  void initState() {
    super.initState();
    _givenDaysController = TextEditingController(text: widget.manager.paidVacationInfo(widget.givenDate)!.givenDays.toString());
    _lapseYear = widget.givenDate.year + 2;
    _lapseMonth = widget.givenDate.month;
    _lapseDay = widget.givenDate.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('付与内容の修正'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AdBannerWidget(),
            Container(
              margin: const EdgeInsets.only(left: 30, top: 30, right: 30, bottom: 10),
              child: _inputGivenDaysForm(),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              child: _showGivenDate(),
            ),
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(10),
                  child: _dateForm(),
                ),
                Text('※ 最低でも2年間は有効が保証されます', style: TextStyle(color: Theme.of(context).hintColor),),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 40, bottom: 40),
              child: _buttons(),
            )

          ],
        ),
      ),
    );
  }

  /// 付与日数入力フォーム
  Widget _inputGivenDaysForm() {
    return TextFormField(
        controller: _givenDaysController,
        maxLength: 2,
        maxLines: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context).textTheme.headline4,
        decoration: InputDecoration(
          label: Text('有給付与日数 *', style: Theme.of(context).textTheme.headline5,),
        ),
        // エラー時処理
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (String? daysStr) {
          // 入力がされているか
          if (daysStr == null) {
            return null;
          } else if (daysStr.isEmpty) {
            return '入力が必須です';
          }
          // 正しい値か
          final days = int.tryParse(daysStr);
          return days == null || days < 1
              ? '1~99を入力してください'
              : null;
        },
      );
  }

  /// 付与日の表示
  Widget _showGivenDate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('付与日: ', style: Theme.of(context).textTheme.headline6?.copyWith(color: Theme.of(context).disabledColor),),
        Text(widget.givenDate.year.toString(),
          style: Theme.of(context).textTheme.headline5?.copyWith(color: Theme.of(context).disabledColor),),
        Text('年', style: Theme.of(context).textTheme.subtitle1,),
        Text(widget.givenDate.month.toString().padLeft(2, '0'),
          style: Theme.of(context).textTheme.headline5?.copyWith(color: Theme.of(context).disabledColor),),
        Text('月', style: Theme.of(context).textTheme.subtitle1,),
        Text(widget.givenDate.day.toString().padLeft(2, '0'),
          style: Theme.of(context).textTheme.headline5?.copyWith(color: Theme.of(context).disabledColor),),
        Text('日', style: Theme.of(context).textTheme.subtitle1,),
      ],
    );
  }

  /// 日付入力フォーム
  Widget _dateForm() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('失効日: ', style: Theme.of(context).textTheme.headline6,),
        DropdownButton<int>(
          dropdownColor: Theme.of(context).backgroundColor,
          items: Lists.convertNumListToWidgetList(context, Lists.create(widget.givenDate.year+2, widget.givenDate.year+7)),
          value: _lapseYear,
          style: Theme.of(context).textTheme.headline5,
          underline: Container(height: 2, color: Colors.black45),
          menuMaxHeight: _menuMaxHeight,
          onChanged: (int? newYear) {
            if (newYear == null) {
              return;
            }
            setState(() {
              _lapseYear = newYear;
            });
          },
        ),
        Text('年', style: Theme.of(context).textTheme.subtitle1,),

        DropdownButton<int>(
          dropdownColor: Theme.of(context).backgroundColor,
          items: _lapseYear == widget.givenDate.year+2
              ? Lists.convertNumListToWidgetList(context, Lists.create(widget.givenDate.month, 12), 2) // 下限を設定
              : Lists.convertNumListToWidgetList(context, Lists.create(1, 12), 2),
          value: _lapseMonth,
          style: Theme.of(context).textTheme.headline5,
          underline: Container(height: 2, color: Colors.black45),
          menuMaxHeight: _menuMaxHeight,
          onChanged: (int? newMonth) {
            if (newMonth == null) {
              return;
            }
            setState(() {
              _lapseMonth = newMonth;
            });
          },
        ),
        Text('月', style: Theme.of(context).textTheme.subtitle1,),

        DropdownButton<int>(
          dropdownColor: Theme.of(context).backgroundColor,
          items: _lapseYear == widget.givenDate.year+2 && _lapseMonth == widget.givenDate.month
              ? Lists.convertNumListToWidgetList(context, Lists.create(widget.givenDate.day, DateTimes.endOfMonth[_lapseMonth]!), 2) // 下限を設定
              : Lists.convertNumListToWidgetList(context, Lists.create(1, DateTimes.endOfMonth[_lapseMonth]!), 2),
          value: _lapseDay,
          style: Theme.of(context).textTheme.headline5,
          underline: Container(height: 2, color: Colors.black45),
          menuMaxHeight: _menuMaxHeight,
          onChanged: (int? newDay) {
            if (newDay == null) {
              return;
            }
            setState(() {
              _lapseDay = newDay;
            });
          },
        ),
        Text('日',  style: Theme.of(context).textTheme.subtitle1,),
      ],
    );
  }

  /// ボタンの表示
  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
            child: Text('キャンセル', style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),),
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(primary: Theme.of(context).errorColor),
        ),
        ElevatedButton(
          child: Text('保存', style: Theme.of(context).textTheme.headline6?.copyWith(color: Colors.white),),
          onPressed: () {
            // 付与日数未入力の場合
            if (_givenDaysController.value.text.isEmpty) {
              ErrorDialog.show(context: context, detail: '"有給付与日数" の入力が必須です');
              return;
            }
            // 付与日数エラー値の場合
            final givenDays = int.tryParse(_givenDaysController.value.text);
            if (givenDays == null || givenDays < 1) {
              ErrorDialog.show(context: context, detail: ' "有給付与日数" は 1 ~ 99 を入力してください');
              return;
            }
            // 付与日数を設定
            // 修正前の付与日数を覚えておく
            final prevGivenDay = widget.manager.paidVacationInfo(widget.givenDate)!.givenDays;
            if (!widget.manager.setGivenDays(widget.givenDate, givenDays)) {
              ErrorDialog.show(
                  context: context,
                  detail: '"有給付与日数" には、取得済みの日数以上の値を設定してください\n'
                      '(取得済み: ${widget.manager.paidVacationInfo(widget.givenDate)!.acquisitionTotal} 日)');
              return;
            }
            // 失効日を設定
            final newLapseDate = DateTime(_lapseYear, _lapseMonth, _lapseDay);
            if (!widget.manager.setLapseDate(givenDate: widget.givenDate, value: newLapseDate)) {
              widget.manager.setGivenDays(widget.givenDate, prevGivenDay); // 付与日数を元の値に設定
              ErrorDialog.show(context: context, detail: '"失効日" は、付与日から2年未満には設定できません');
              return;
            }
            // 同じ付与日でストレージの内容を上書き
            // 付与日数がキーになるため、付与日数を変えられるようにすると元のデータの削除が必要になる
            LocalStorageManager.writeGivenDaysInfo(GivenDaysInfo(givenDays, widget.givenDate, newLapseDate));
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => DisplayPage(manager: widget.manager)),
                (route) => false);
          },
        )
      ],
    );
  }
}