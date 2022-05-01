import 'package:flutter/material.dart';
/// エラーダイアログを表示するクラス
class ErrorDialog {
  static void show({required BuildContext context, required String detail}) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('エラー', style: TextStyle(color: Theme.of(context).errorColor),),
            content: Text(detail),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK', style: Theme.of(context).textTheme.headline5?.copyWith(color: Theme.of(context).primaryColor))
              )
            ],
          );
        }
    );
  }
}