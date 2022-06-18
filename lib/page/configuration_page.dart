import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:paid_vacation_manager/utility/api/ad_banner.dart';
import 'package:paid_vacation_manager/utility/api/google_calendar.dart';
import 'package:paid_vacation_manager/utility/api/google_sign_in_manager.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';
import 'package:paid_vacation_manager/config/configure.dart';

/// アプリの設定画面
class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ConfigurationPageState();

}

class ConfigurationPageState extends State<ConfigurationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: _configurationList()
    );
  }

  /// 設定項目リスト
  Widget _configurationList() {
    return ListView(
      children: [
        const AdBannerWidget(),
        SwitchListTile(
          secondary: const Icon(Icons.sync),
          title: Text('Googleカレンダーと同期', style: Theme.of(context).textTheme.titleLarge,),
          value: Configure.instance.isSyncGoogleCalendar,
          onChanged: (bool isSync) async {
            // 値の設定
            setState(() {
              Configure.instance.isSyncGoogleCalendar = isSync;
              LocalStorageManager.writeIsSyncGoogleCalendar(isSync);
            });
            if (isSync) {
              // 同期設定をONにした場合、サインインを試みる
              if (!await GoogleSignInManager.signInGoogle(scope: [GoogleCalendar.calendarScope])) {
                log('ログイン失敗');
                // 失敗したら同期設定OFFにする
                setState(() {
                  Configure.instance.isSyncGoogleCalendar = false;
                  LocalStorageManager.writeIsSyncGoogleCalendar(false);
                });
              }
            } else {
              // 同期設定をOFFにした場合
              // 認証情報を初期化する
              if (await GoogleSignInManager.isSignedIn()) {
                GoogleSignInManager.disconnect();
              }
            }
          },
        ),
      ],
    );
  }

}