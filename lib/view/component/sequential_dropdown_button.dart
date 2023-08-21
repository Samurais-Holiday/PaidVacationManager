import 'package:flutter/material.dart';

/// 特定の範囲を選択するドロップダウンボタン
class SequentialDropdownButton extends DropdownButton<int> {
  /// コンストラクタ
  SequentialDropdownButton({
      Key? key,
      required BuildContext context,
      int? value,
      required int start,
      required int end,
      required void Function(int) onChanged
  }) : super(
      key: key,
      dropdownColor: Theme.of(context).scaffoldBackgroundColor,
      style: Theme.of(context).textTheme.headlineSmall,
      value: value ?? start,
      items: _createItemList(context, start, end),
      onChanged: (int? value) {
        if (value != null) {
          onChanged(value);
        }
      }
  );

  /// 指定された範囲のアイテムを生成する
  static List<DropdownMenuItem<int>> _createItemList(BuildContext context, int start, int end) {
    final list = <DropdownMenuItem<int>>[];
    for (int i = start; i <= end; i++) {
      list.add(DropdownMenuItem<int>(
          value: i,
          child: Text('$i', style: TextStyle(color: Theme.of(context).shadowColor),)
      ));
    }
    return list;
  }
}