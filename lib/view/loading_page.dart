import 'package:flutter/material.dart';

import '../model/settings.dart';
import '../repository/device_storage.dart';
import '../repository/paid_vacation_repository.dart';
import 'paid_vacation_list_page.dart';

/// 起動時読み込み画面
class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {

  @override
  void initState() {
    super.initState();
    final paidVacationFuture = PaidVacationRepository(repository: DeviceStorage()).readAll();
    final settings = Settings(repository: DeviceStorage());
    paidVacationFuture.then((list) {
      settings.load().then((_) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => PaidVacationListPage(list: list, settings: settings)),
                (route) => false
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('読込み中……'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
