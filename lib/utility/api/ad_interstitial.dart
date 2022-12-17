import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMobのインタースティシャル広告を表示するクラス
class AdInterstitial {
  /// シングルトンインスタンス
  static final _adInterstitial = AdInterstitial._internal();
  static AdInterstitial get instance => _adInterstitial;

  /// プライベートコンストラクタ
  AdInterstitial._internal() {
    MobileAds.instance.setAppMuted(true);
  }

  /// InterstitialAdのインスタンス
  InterstitialAd? _ad;
  bool get _isLoaded => _ad != null;

  /// 読込みに失敗した回数
  var _loadFailedCount = 0;

  /// 広告を表示する
  Future show() async {
    // AdSenseに広告の時間が長いと怒られたので、表示する頻度を落とす
    if (math.Random().nextInt(10) <= 6) {
      return;
    }
    if (!_isLoaded) {
      await _load();
    }
    if (_isLoaded) {
      // loadへのアクセスが不要になった場合にdisposeするように設定
      _ad!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) => ad.dispose(),
        onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
      );
      // 表示する
      _ad!.show();
      // 次の表示のために読み込んでおく
      _ad = null;
      _load();
    }
  }

  /// 広告の読込みを行う
  /// 失敗した場合には最大5回まで試行する
  Future _load() async => await InterstitialAd.load(
    adUnitId: _unitId,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadFailedCount = 0;
        },
        onAdFailedToLoad: (error) async {
          _ad = null;
          _loadFailedCount++;
          dev.log('インタースティシャル広告の読込みに失敗 ($_loadFailedCount回目)');
          if (_loadFailedCount < 5) {
            await _load();
          }
        }
    ),
  );

  /// 広告ユニットID取得
  static String get _unitId {
    if (kDebugMode) {
      // テスト用ID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-6208003004365138/6572613175'
        : 'iOS is TODO';
  }
}