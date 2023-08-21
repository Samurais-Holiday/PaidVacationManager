import 'package:flutter/material.dart';

/// 削除可能リストWidget
class DismissibleListView {
  /// スクロール可能なリストを構築
  static ListView builder<T>({
      required BuildContext context,
      required Iterable<T> items,
      required ListTile Function(T) listTileBuilder,
      required void Function(T) onDismissed,
  }) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, index) {
        return Dismissible(
          key: UniqueKey(),
          background: Container(color: Theme.of(context).colorScheme.error,),
          onDismissed: (_) => onDismissed(items.elementAt(index)),
          child: Column(
            children: [
              listTileBuilder(items.elementAt(index)),
              Container(
                margin: const EdgeInsets.only(right: 10, left: 10),
                height: 2,
                color: Theme.of(context).highlightColor,
              ),
            ],
          )
        );
      },
    );
  }
}