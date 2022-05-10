import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:paid_vacation_manager/data/given_days_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_info.dart';
import 'package:paid_vacation_manager/data/paid_vacation_manager.dart';
import 'package:paid_vacation_manager/display_page.dart';
import 'package:paid_vacation_manager/utility/api/ad_banner.dart';
import 'package:paid_vacation_manager/utility/date_times.dart';
import 'package:paid_vacation_manager/utility/error_dialog.dart';
import 'package:paid_vacation_manager/utility/lists.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';

/// 新しく付与された有給情報を追加する
class AddPage extends StatefulWidget {
  const AddPage({Key? key, required this.manager, this.isCarriedOverDaysMode = false}) : super(key: key);
  final PaidVacationManager manager;
  final bool isCarriedOverDaysMode;

  @override
  State<StatefulWidget> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  static const double _menuMaxHeight = 450; // ドロップダウンの高さ
  final _givenDaysController = TextEditingController();
  var _givenYear = DateTime.now().year;
  var _givenMonth = DateTime.now().month;
  var _givenDay = DateTime.now().day;
  var _lapseYear = DateTime.now().year+2;
  var _lapseMonth = DateTime.now().month;
  var _lapseDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: Text(widget.isCarriedOverDaysMode ? '繰り越し日数の登録' : '付与日数の新規追加'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AdBanner(adSize: AdSize.fullBanner),
            Container(
              margin: const EdgeInsets.only(left: 30, top: 30, right: 30, bottom: 20),
              child: _inputGivenDaysForm(),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              child: _inputGivenDateForm(),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              child: _inputLapseDateForm(),
            ),
            Container(
              margin: const EdgeInsets.all(30),
              child: _registrationButton(),
            )
          ],
        ),
      ),
    );
  }

  /// 付与日数入力フォーム
  Widget _inputGivenDaysForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextFormField(
          controller: _givenDaysController,
          autofocus: true,
          maxLength: 2,
          maxLines: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: Theme.of(context).textTheme.headline4,
          decoration: InputDecoration(
              labelText: widget.isCarriedOverDaysMode ? '繰り越し日数 *' : '有給付与日数 *',
              labelStyle: Theme.of(context).textTheme.headline5,
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
        ),

        if (!widget.isCarriedOverDaysMode)
          Text(
            '※ 繰り越し日数は含めない',
            style: TextStyle(color: Theme.of(context).hintColor),
          )
      ],
    );
  }

  /// 付与日入力フォーム
  Widget _inputGivenDateForm() {
    return Column(
      children: [
        _createInputDateForm(isGivenDate: true),
        if (widget.isCarriedOverDaysMode)
          Text(
            '※ 繰り越した日ではなく、付与された日を入力して下さい',
            style: TextStyle(color: Theme.of(context).hintColor),
          )
      ],
    );
  }

  /// 失効日入力フォーム
  Widget _inputLapseDateForm() {
    return Column(
      children: [
        _createInputDateForm(isGivenDate: false),
        Text('※ 最低でも2年間は有効が保証されます', style: TextStyle(color: Theme.of(context).hintColor),)
      ],
    );
  }

  /// 日付入力フォーム
  Widget _createInputDateForm({required bool isGivenDate}) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            isGivenDate ? '付与日: ' : '失効日: ',
            style: Theme.of(context).textTheme.headline6,
          ),
          DropdownButton<int>(
            dropdownColor: Theme.of(context).backgroundColor,
            items: isGivenDate
                  ? Lists.convertNumListToWidgetList(context, Lists.create(DateTime.now().year-5, DateTime.now().year+5))
                  : Lists.convertNumListToWidgetList(context, Lists.create(_givenYear+2, _givenYear+7)),
            value: isGivenDate ? _givenYear : _lapseYear,
            style: Theme.of(context).textTheme.headline5,
            underline: Container(height: 2, color: Colors.black45),
            menuMaxHeight: _menuMaxHeight,
            onChanged: (int? newYear) {
              if (newYear == null) {
                return;
              }
              setState(() {
                if (isGivenDate) {
                  _givenYear = newYear;
                } else {
                  _lapseYear = newYear;
                }
                _invalidInputDateThenReset(isGivenDate);
              });
            },
          ),
          Text('年', style: Theme.of(context).textTheme.subtitle1,),

          DropdownButton<int>(
            dropdownColor: Theme.of(context).backgroundColor,
            items: isGivenDate
                ? Lists.convertNumListToWidgetList(context, Lists.create(1, 12), 2) // 付与日は全部表示
                : _lapseYear == _givenYear+2
                    ? Lists.convertNumListToWidgetList(context, Lists.create(_givenMonth, 12), 2) // 失効日かつ、付与日から2年後の場合は下限を設ける
                    : Lists.convertNumListToWidgetList(context, Lists.create(1, 12), 2), // 失効日が付与日から2年後以外は下限を設けない
            value: isGivenDate ? _givenMonth : _lapseMonth,
            style: Theme.of(context).textTheme.headline5,
            underline: Container(height: 2, color: Colors.black45),
            menuMaxHeight: _menuMaxHeight,
            onChanged: (int? newMonth) {
              if (newMonth == null) {
                return;
              }
              setState(() {
                if (isGivenDate) {
                  _givenMonth = newMonth;
                } else {
                  _lapseMonth = newMonth;
                }
                _invalidInputDateThenReset(isGivenDate);
              });
            },
          ),
          Text('月', style: Theme.of(context).textTheme.subtitle1,),

          DropdownButton<int>(
            dropdownColor: Theme.of(context).backgroundColor,
            items: isGivenDate
                ? Lists.convertNumListToWidgetList(context, Lists.create(1, DateTimes.endOfMonth[_givenMonth]!), 2) // 付与日の場合全部表示
                : _lapseYear == _givenYear+2 && _lapseMonth == _givenMonth
                    ? Lists.convertNumListToWidgetList(context, Lists.create(_givenDay, DateTimes.endOfMonth[_lapseMonth]!), 2)
                    : Lists.convertNumListToWidgetList(context, Lists.create(1, DateTimes.endOfMonth[_lapseMonth]!), 2),
            value: isGivenDate ? _givenDay : _lapseDay,
            style: Theme.of(context).textTheme.headline5,
            underline: Container(height: 2, color: Colors.black45),
            menuMaxHeight: _menuMaxHeight,
            onChanged: (int? newDay) {
              if (newDay == null) {
                return;
              }
              setState(() {
                if (isGivenDate) {
                  _givenDay = newDay;
                } else {
                  _lapseDay = newDay;
                }
                _invalidInputDateThenReset(isGivenDate);
              });
            },
          ),
          Text('日',  style: Theme.of(context).textTheme.subtitle1,),
        ],
    );
  }

  /// 付与日と失効日の関係が2年未満の場合に再設定する
  void _invalidInputDateThenReset(bool isGivenDate) {
    if (_invalidInputDate()) {
      if (isGivenDate) {
        _lapseYear = _givenYear+2;
        _lapseMonth = _givenMonth;
        _lapseDay = _givenDay;
      } else {
        _givenYear = _lapseYear-2;
        _givenMonth = _lapseMonth;
        _givenDay = _lapseDay;
      }
    }
  }

  /// 付与日と失効日の入力値が無効か
  bool _invalidInputDate() {
    return DateTime(_lapseYear, _lapseMonth, _lapseDay).isBefore(DateTime(_givenYear+2, _givenMonth, _givenDay));
  }

  /// 登録ボタン
  /// 入力を保存し、画面遷移を行う
  /// 入力値に不備がある場合はダイヤルボックスでユーザーに知らせる
  Widget _registrationButton() {
    return ElevatedButton(
        onPressed: () {
          // 付与日数のチェック
          final givenDaysStr = _givenDaysController.value.text;
          if (givenDaysStr.isEmpty) {
            ErrorDialog.show(context: context, detail: '"有給付与日数" は入力が必須です');
            return;
          }
          final givenDays = int.tryParse(givenDaysStr);
          if (givenDays == null || givenDays < 1) {
            ErrorDialog.show(context: context, detail: '"有給付与日数" は 1~99 を入力してください');
            return;
          }
          // 付与日のチェック
          if (widget.manager.paidVacationInfo(DateTime(_givenYear, _givenMonth, _givenDay)) != null) {
            ErrorDialog.show(context: context, detail: '同じ付与日の有給情報が既に登録されています');
            return;
          }
          // 失効日のチェック
          if (_invalidInputDate()) {
            ErrorDialog.show(context: context, detail: '"失効日" は、付与日から2年未満には設定できません');
            return;
          }
          // 入力が正しければ確認ダイアログを表示する
          _confirmationDialog(givenDays: givenDays);
        },
        child: Text('登録', style: Theme.of(context).textTheme.headline5?.copyWith(color: Colors.white),)
    );
  }

  /// 確認ダイアログを表示する
  /// OKの場合は表示画面へ遷移する
  void _confirmationDialog({required int givenDays}) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('登録内容確認', style: TextStyle(color: Theme.of(context).primaryColor),),
            content: Text(
                '以下の内容で登録します\n\n'
                    '　・有給付与日数: $givenDays日\n'
                    '　・付与日: $_givenYear年 $_givenMonth月 $_givenDay日\n'
                    '　・失効日: $_lapseYear年 $_lapseMonth月 $_lapseDay日'
            ),
            actions: [
              TextButton(
                child: Text('キャンセル', style: Theme.of(context).textTheme.headline6?.copyWith(color: Theme.of(context).errorColor),),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('OK', style: Theme.of(context).textTheme.headline5?.copyWith(color: Theme.of(context).primaryColor)),
                onPressed: () {
                  final givenDaysInfo = GivenDaysInfo(
                      givenDays,
                      DateTime(_givenYear, _givenMonth, _givenDay),
                      DateTime(_lapseYear, _lapseMonth, _lapseDay));
                  if (widget.manager.addInfo(PaidVacationInfo(givenDaysInfo))) {
                    // 追加に成功した場合
                    // ストレージへ保存
                    LocalStorageManager.writeGivenDaysInfo(givenDaysInfo);
                    // 表示画面へ遷移
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (builder) => DisplayPage(
                                  manager: widget.manager,
                                  givenDateToDisplay: DateTime(_givenYear, _givenMonth, _givenDay),
                            )
                        ),
                        (_) => false
                    );
                  } else {
                    // 追加に失敗した場合
                    Navigator.pop(context);
                    ErrorDialog.show(context: context, detail: '登録に失敗しました');
                  }
                },
              )
            ],
          );
        }
     );
  }
}