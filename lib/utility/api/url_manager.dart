import 'package:url_launcher/url_launcher.dart';

/// 各サイトのURLを管理するクラス
class UrlManager {
  /// プライバシーポリシー
  static Future launchPolicy() => launchUrl(
      Uri.parse('https://samurais-holiday.com/%e5%8d%8a%e4%bc%91%e5%af%be%e5%bf%9c%e3%81%8b%e3%82%93%e3%81%9f%e3%82%93%e6%9c%89%e7%b5%a6%e7%ae%a1%e7%90%86/privacy-policy/'));
}
