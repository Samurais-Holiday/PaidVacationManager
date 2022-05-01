import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:paid_vacation_manager/top_page.dart';

void main() {
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
