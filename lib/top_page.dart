import 'package:flutter/material.dart';
import 'package:paid_vacation_manager/add_page.dart';
import 'package:paid_vacation_manager/display_page.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';
import 'package:paid_vacation_manager/utility/configure.dart';

import 'data/paid_vacation_manager.dart';

/// ローカルストレージから有給情報の読み出し、登録情報の内容を受けて画面遷移を行う
class TopPage extends StatefulWidget {
  const TopPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {

  @override
  void initState() {
    super.initState();
    // ストレージのデータから有給情報を生成
    LocalStorageManager.readPaidVacationData().then((manager) async {
      if (manager == null) {
        // 登録情報がない場合
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AddPage(manager: PaidVacationManager())),
            (route) => false
        );
        return;
      } else {
        // 登録情報がある場合
        await Configure.instance.loadIsSyncGoogleCalendar();
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DisplayPage(manager: manager)),
            (route) => false
        );
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('読込み中……'),
      ),
      body: const Center(
        child: Text('読込み中……'),
      ),
    );
  }
}
