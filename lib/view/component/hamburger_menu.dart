import 'package:flutter/material.dart';

import '../../model/settings.dart';
import '../../utility/api/url_manager.dart';
import '../settings_page.dart';

/// ハンバーガーボタン押下時のドロワーWidget
class HamburgerMenu extends Drawer {
  HamburgerMenu({required BuildContext context, required Settings settings, void Function()? onPopped, Key? key}) : super(
      key: key,
      backgroundColor: Theme.of(context).primaryColor,
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: Text('設定', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsPage(settings: settings))
              );
              onPopped?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.link, color: Colors.white),
            title: Text('プライバシーポリシー', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),),
            onTap: () async {
              Navigator.pop(context);
              await UrlManager.launchPolicy();
              onPopped?.call();
            },
          ),
        ],
      )
  );

}