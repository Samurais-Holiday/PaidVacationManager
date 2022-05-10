import 'package:flutter/material.dart';

/// ユーザーへの通知を行うダイアログ
class InformationDialog {
  static Future show({required final BuildContext context, required final String info}) async {
    await showDialog(context: context, builder: (context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).backgroundColor,
        content: Text(info),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: Theme.of(context).textTheme.headline5?.copyWith(color: Theme.of(context).primaryColor),)),
        ],
      );
    });
  }
}