import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:paid_vacation_manager/page/top_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 各初期化処理(ユーザビリティを重視するため、処理は非同期で行う)
  MobileAds.instance.initialize(); // AdMob
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); // 画面の向きを固定
  Firebase.initializeApp();  // Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '有給管理',
      theme: ThemeData(
        primarySwatch: Colors.green,
        backgroundColor: Colors.yellow.shade100,
        dialogBackgroundColor: Colors.yellow.shade100,
        scaffoldBackgroundColor: Colors.yellow.shade100,
      ),

      // 多言語化
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("en"),
        Locale("ja"),
      ],
      home: const TopPage(),
    );
  }
}
