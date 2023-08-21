import 'package:flutter/material.dart';
import 'package:paid_vacation_manager/model/am_pm.dart';

import '../model/acquisition.dart';
import '../model/acquisition_factory.dart';
import '../model/acquisition_half.dart';
import '../model/acquisition_hours.dart';
import '../model/date.dart';
import '../model/settings.dart';
import 'component/ad_banner.dart';
import 'component/input_date_field.dart';
import 'component/ok_cancel_button.dart';
import 'component/sequential_dropdown_button.dart';

/// 有給取得情報を表示/編集する画面
class AcquisitionSinglePage extends StatefulWidget {
  final String _title;
  final Acquisition? _before;
  final Date _first;
  final Date _last;
  final Settings _settings;
  final String _acceptText;
  final bool Function(Acquisition?, Acquisition) _onAccepted;

  /// コンストラクタ
  const AcquisitionSinglePage({
      Key? key,
      required String title,
      Acquisition? before,
      required Date first,
      required Date last,
      required Settings settings,
      required String acceptText,
      required bool Function(Acquisition?, Acquisition) onAccepted,
  }) :
        _title = title,
        _before = before,
        _first = first,
        _last = last,
        _settings = settings,
        _acceptText = acceptText,
        _onAccepted = onAccepted,
        super(key: key);

  @override
  State<StatefulWidget> createState() => _AcquisitionSinglePageState();
}

enum _AcquisitionType {
  day,
  half,
  hours,
}

class _AcquisitionSinglePageState extends State<AcquisitionSinglePage> {
  /// 取得日
  Date _date;
  /// 取得日(ラベル用)
  final TextEditingController _dateLabel;
  /// 有給種別
  _AcquisitionType _type;
  /// 午前/午後
  AmPm _amPm;
  /// 時間単位取得時間
  int _hours;
  /// 説明
  final TextEditingController _description;

  /// コンストラクタ
  _AcquisitionSinglePageState()
      : _date = Date.today(),
        _dateLabel = TextEditingController(text: '${Date.today().year} 年 ${Date.today().month} 月 ${Date.today().day} 日 (${Date.today().weekdayText})'),
        _type = _AcquisitionType.day,
        _amPm = AmPm.am,
        _hours = 1,
        _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setFieldParameter();
  }

  /// 初期値を設定
  void _setFieldParameter() {
    final before = widget._before;
    if (before == null) {
      return;
    }
    _date = before.date;
    _dateLabel.text = '${_date.year} 年 ${_date.month} 月 ${_date.day} 日 (${_date.weekdayText})';
    _description.text = before.description;
    if (before is AcquisitionHalf) {
      _type = _AcquisitionType.half;
      _amPm = before.amPm;
    } else if (before is AcquisitionHours) {
      _type = _AcquisitionType.hours;
      _hours = before.duration.hours();
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!widget._settings.hideAd)
            const AdBannerWidget(),
          Container(
            margin: const EdgeInsets.all(10),
            child: _dateField(),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: _acquisitionTypeRadio(),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: _acquisitionOption(),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: _descriptionField(),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: _okCancelButton(),
          ),
        ],
      ),
    );
  }

  /// 取得日表示Widget
  Widget _dateField() {
    return InputDateField(
      labelText: '取得日',
      initial: _date,
      first: widget._first,
      last: widget._last,
      onChanged: (date) => _date = date,
    );
  }

  /// 有給種別ラジオボタン
  Widget _acquisitionTypeRadio() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<_AcquisitionType>(
                  title: const Text('全休'),
                  value: _AcquisitionType.day,
                  groupValue: _type,
                  onChanged: (_AcquisitionType? type) {
                    if (type == null) {
                      return;
                    }
                    setState(() => _type = type);
                  }
              ),
            ),
            Expanded(
              child: RadioListTile<_AcquisitionType>(
                  title: const Text('半休'),
                  value: _AcquisitionType.half,
                  groupValue: _type,
                  onChanged: (_AcquisitionType? type) {
                    if (type == null) {
                      return;
                    }
                    setState(() => _type = type);
                  }
              ),
            ),
            Expanded(
              child: RadioListTile<_AcquisitionType>(
                  title: const Text('時間'),
                  value: _AcquisitionType.hours,
                  groupValue: _type,
                  onChanged: (_AcquisitionType? type) {
                    if (type == null) {
                      return;
                    }
                    setState(() => _type = type);
                  }
              ),
            ),
          ],
        ),
        Container(
          height: 2,
          color: Colors.black12,
        ),
      ],
    );
  }

  /// 取得単位別オプション
  Widget _acquisitionOption() {
    return Column(
      children: [
        if (_type == _AcquisitionType.half)
          _amOrPmRadio(),
        if (_type == _AcquisitionType.hours)
          _hoursField(),
        if (_type != _AcquisitionType.day)
          Container(
            height: 2,
            color: Colors.black12,
          ),
      ],
    );
  }

  /// 午前/午後ラジオボタン
  Widget _amOrPmRadio() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<AmPm>(
            title: const Text('午前'),
            value: AmPm.am,
            groupValue: _amPm,
            onChanged: (AmPm? amPm) {
              if (amPm == null) {
                return;
              }
              setState(() => _amPm = amPm);
            }
          ),
        ),
        Expanded(
          child: RadioListTile<AmPm>(
            title: const Text('午後'),
            value: AmPm.pm,
            groupValue: _amPm,
            onChanged: (AmPm? amPm) {
              if (amPm == null) {
                return;
              }
              setState(() => _amPm = amPm);
            }
          ),
        ),
      ],
    );
  }

  /// 時間単位取得時間
  Widget _hoursField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SequentialDropdownButton(
          context: context,
          value: _hours,
          start: 0,
          end: 8,
          onChanged: (int hours) {
            setState(() => _hours = hours);
          },
        ),
        Text('時間', style: Theme.of(context).textTheme.titleMedium,),
      ],
    );
  }

  /// 説明欄
  Widget _descriptionField() {
    return TextFormField(
      controller: _description,
      maxLength: 100,
      maxLines: null,
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: InputDecoration(
        label: Text('メモ', style: Theme.of(context).textTheme.titleLarge,)
      ),
    );
  }

  /// OK/Cancelボタン
  Widget _okCancelButton() {
    return OkCancelButton(
      context: context,
      acceptText: widget._acceptText,
      onAccepted: () {
        final after = AcquisitionFactory.instance.create(
          date: _date,
          amPm: _type == _AcquisitionType.half ? _amPm : null,
          hours: _type == _AcquisitionType.hours ? _hours : null,
          description: _description.value.text,
        );
        if (widget._onAccepted(widget._before, after)) {
          Navigator.pop(context);
        }
      },
      onRejected: () => Navigator.pop(context),
    );
  }
}