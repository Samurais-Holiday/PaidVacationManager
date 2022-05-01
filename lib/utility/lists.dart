import 'package:flutter/material.dart';

/// リストについてutility機能を提供するクラス
class Lists {
  /// 昇順のリストを生成する
  static List<int> create(int begin, int end) {
    final list = <int>[];
    for (var i = begin; i <= end; i++) {
      list.add(i);
    }
    return list;
  }

  /// 数値のリストからWidgetのドロップダウンメニューのリストに変換する
  static List<DropdownMenuItem<int>>? convertNumListToWidgetList(BuildContext context, List<int> list, [int? width]) {
    return list.map<DropdownMenuItem<int>>((int value) {
      return DropdownMenuItem<int>(
        value: value,
        child: Text(
          width == null ? value.toString() : value.toString().padLeft(width, '0'),
          style: TextStyle(color: Theme.of(context).shadowColor),),
      );
    }).toList();
  }

}