import 'package:url_launcher/url_launcher.dart';

/// 各サイトのURLを管理するクラス
class UrlManager {
  /// プライバシーポリシー
  static final _policy = Uri.parse('https://github.com/Samurais-Holiday/PaidVacationManager/blob/main/privacy_policy.txt');
  static Future launchPolicy() => launchUrl(_policy);
}
