import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/date.dart';
import '../model/given_days.dart';
import '../model/settings.dart';
import 'component/ad_banner.dart';
import 'component/dialogs.dart';
import 'component/input_date_field.dart';
import 'component/ok_cancel_button.dart';

/// 付与日数情報編集ページ
class GivenDaysEditPage extends StatefulWidget {
  final String _title;
  final GivenDays? _before;
  final Date _firstDate;
  final Date _lastDate;
  final Settings _settings;
  final String? _acceptText;
  final bool Function(GivenDays? before, GivenDays after) _onAccepted;

  /// コンストラクタ
  const GivenDaysEditPage({
      Key? key,
      required String title,
      GivenDays? before,
      required Date firstDate,
      required Date lastDate,
      String? acceptText,
      required bool Function(GivenDays?, GivenDays) onAccepted,
      required Settings settings,
  }) :
        _title = title,
        _before = before,
        _firstDate = firstDate,
        _lastDate = lastDate,
        _acceptText = acceptText,
        _onAccepted = onAccepted,
        _settings = settings,
        super(key: key);

  @override
  State<StatefulWidget> createState() => _GivenDaysEditPageState();
}

class _GivenDaysEditPageState extends State<GivenDaysEditPage> {
  Date _givenDate;
  final TextEditingController _givenDaysText;

  /// コンストラクタ
  _GivenDaysEditPageState() : _givenDate = Date.today(), _givenDaysText = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget._before != null) {
      _givenDate = widget._before!.start;
      _givenDaysText.text = '${widget._before!.days}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget._title),),
      body: _body(),
    );
  }

  /// ボディ部
  Widget _body() {
    return Column(
      children: [
        if (!widget._settings.hideAd)
          const AdBannerWidget(),
        Container(
          margin: const EdgeInsets.all(10),
          child: _givenDateField(),
        ),
        Container(
          margin: const EdgeInsets.all(10),
          child: _givenDaysField(),
        ),
        Container(
          margin: const EdgeInsets.all(10),
          child: _okCancelButton(),
        ),
      ],
    );
  }

  /// 付与日入力欄
  Widget _givenDateField() {
    return InputDateField(
      labelText: '付与日',
      initial: _givenDate,
      first: widget._firstDate,
      last: widget._lastDate,
      onChanged: (date) => _givenDate = date,
    );
  }

  /// 付与日数入力欄
  Widget _givenDaysField() {
    return TextFormField(
      maxLines: 1,
      maxLength: 2,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: InputDecoration(label: Text('付与日数', style: Theme.of(context).textTheme.titleLarge,)),
      controller: _givenDaysText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (daysStr) {
        if (daysStr == null) {
          return null;
        }
        if (daysStr.isEmpty) {
          return '入力が必須です';
        }
        final days = int.tryParse(daysStr);
        return days == null || days < 1
            ? '不正な入力です'
            : null;
      },
    );
  }
  /// OK/Cancelボタン
  Widget _okCancelButton() {
    return OkCancelButton(
      context: context,
      acceptText: widget._acceptText,
      onAccepted: () async {
        final days = int.tryParse(_givenDaysText.text);
        if (days == null) {
          await Dialogs.showError(
            context: context,
            text: '付与日数を入力してください'
          );
          return;
        }
        if (widget._onAccepted(widget._before, GivenDays(days: days, start: _givenDate))) {
          Navigator.pop(context);
        }
      },
      onRejected: () {
        Navigator.pop(context);
      },
    );
  }
}