import 'package:flutter/material.dart';

import '../../model/date.dart';

/// TextField と showDatePickerを使用し、日付の入力を行うフィールド
class InputDateField extends StatefulWidget {
  final Date _initial;
  final Date _first;
  final Date _last;
  final String? _labelText;
  final bool? _enabled;
  final void Function(Date)? _onChanged;

  /// コンストラクタ
  const InputDateField({
      required Date initial,
      required Date first,
      required Date last,
      String? labelText,
      bool? enabled,
      void Function(Date)? onChanged,
      Key? key
  }) :
        _initial = initial,
        _first = first,
        _last = last,
        _labelText = labelText,
        _enabled = enabled,
        _onChanged = onChanged,
        super(key: key);

  @override
  State<StatefulWidget> createState() => _InputDateFieldState();
}

class _InputDateFieldState extends State<InputDateField> {
  final TextEditingController _controller;

  /// コンストラクタ
  _InputDateFieldState() : _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = '${widget._initial.year} 年 ${widget._initial.month} 月 ${widget._initial.day} 日 (${widget._initial.weekdayText})';
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget._enabled,
      style: Theme.of(context).textTheme.headlineSmall,
      controller: _controller,
      decoration: widget._labelText != null
          ? InputDecoration(label: Text(widget._labelText!, style: Theme.of(context).textTheme.titleLarge))
          : null,
      readOnly: true,
      onTap: () async {
        if (widget._enabled != null && !widget._enabled!) {
          return;
        }
        final dateTime = await showDatePicker(
            context: context,
            locale: const Locale('ja'),
            initialDate: widget._initial,
            firstDate: widget._first,
            lastDate: widget._last
        );
        if (dateTime == null) {
          return;
        }
        final date = Date.fromDateTime(dateTime);
        setState(() {
          _controller.text = '${date.year} 年 ${date.month} 月 ${date.day} 日 (${date.weekdayText})';
        });
        if (widget._onChanged != null) {
          widget._onChanged!(date);
        }
      },
    );
  }
}