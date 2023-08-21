import 'package:flutter/material.dart';

/// OK/Cancelボタン
class OkCancelButton extends StatelessWidget {
  final BuildContext _context;
  final void Function() _onAccepted;
  final void Function() _onRejected;
  final String _acceptText;
  final String _rejectText;

  /// コンストラクタ
  const OkCancelButton({
      Key? key,
      required BuildContext context,
      required void Function() onAccepted,
      required void Function() onRejected,
      String? acceptText,
      String? rejectText,
  }) :
        _context = context,
        _onAccepted = onAccepted,
        _onRejected = onRejected,
        _acceptText = acceptText ?? 'OK',
        _rejectText = rejectText ?? 'キャンセル',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: _onRejected,
            child: Text(_rejectText, style: Theme.of(_context).textTheme.titleMedium?.copyWith(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
          onPressed: _onAccepted,
          child: Text(_acceptText, style: Theme.of(_context).textTheme.titleMedium?.copyWith(color: Colors.white)),
        ),
      ],
    );
  }

}