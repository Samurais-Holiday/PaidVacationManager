import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMobのバナーを表示するクラス
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({Key? key, this.backgroundColor}) : super(key: key);
  final Color? backgroundColor;

  @override
  State<StatefulWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  late BannerAd _banner;

  @override
  void initState() {
    super.initState();
    _banner = _createBanner(AdSize.fullBanner);
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Container(
  //     color: widget.backgroundColor ?? Theme.of(context).backgroundColor,
  //     width: _banner.size.width.toDouble(),
  //     height: _banner.size.height.toDouble(),
  //     child: AdWidget(ad: _banner),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 1.0, width: 1.0,);
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

  static String get _unitId {
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