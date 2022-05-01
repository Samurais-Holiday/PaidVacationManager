import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMobのバナーを表示するクラス
class AdBanner extends StatefulWidget {
  const AdBanner({Key? key, required this.adSize}) : super(key: key);
  final AdSize adSize;

  @override
  State<StatefulWidget> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  late BannerAd _banner;

  @override
  void initState() {
    super.initState();
    _banner = _createBanner(widget.adSize);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      width: _banner.size.width.toDouble(),
      height: _banner.size.height.toDouble(),
      child: AdWidget(ad: _banner),
    );
  }

  @override
  void dispose() {
    _banner.dispose();
    super.dispose();
  }

  BannerAd _createBanner(AdSize size) {
    return BannerAd(
      size: size,
      adUnitId: _unitId,
      listener: BannerAdListener(
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _banner.dispose();
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  String get _unitId {
    if (kDebugMode) {
      // テスト用ID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    //
    return Platform.isAndroid
        ? 'ca-app-pub-6208003004365138/2406686196'
        : 'iOS is TODO';
  }
}