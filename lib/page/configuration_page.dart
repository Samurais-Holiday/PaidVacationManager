import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:paid_vacation_manager/enum/purchase_item.dart';
import 'package:paid_vacation_manager/utility/api/ad_banner.dart';
import 'package:paid_vacation_manager/utility/api/google_calendar.dart';
import 'package:paid_vacation_manager/utility/api/google_sign_in_manager.dart';
import 'package:paid_vacation_manager/utility/api/in_app_purchase_service.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';
import 'package:paid_vacation_manager/config/configure.dart';
import 'package:paid_vacation_manager/utility/error_dialog.dart';
import 'package:paid_vacation_manager/utility/information_dialog.dart';

/// アプリの設定画面
class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ConfigurationPageState();
}

class ConfigurationPageState extends State<ConfigurationPage> {
  late InAppPurchaseService _inAppPurchase;
  bool _isPending = false;

  /// コンストラクタ
  ConfigurationPageState() {
    _inAppPurchase = InAppPurchaseService(
        onCompleted: _deliverProduct,
        onPending: _showPending,
        onError: _showError);
  }

  /// アイテム購入時処理
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == InAppPurchaseService.productTypeToString[PurchaseProductType.hideAd]) {
      await LocalStorageManager.writeHideAd(true);
      await Configure.instance.load();
      setState(() {
        _isPending = false;
      });
      await InformationDialog.show(context: context, info: '広告を非表示にしました');
    }
  }

  /// アイテム購入処理中処理
  void _showPending(PurchaseDetails purchaseDetails) {
    setState(() {
      _isPending = true;
    });
  }

  /// アイテム購入失敗時処理
  Future<void> _showError(PurchaseDetails purchaseDetails) async {
    await ErrorDialog.show(context: context, detail: '購入に失敗しました');
    setState(() {
      _isPending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: _isPending ? _pendingWidget() : _configurationList()
    );
  }

  /// 購入処理中に表示するWidget
  Widget _pendingWidget() {
    return const Center(
        child: CircularProgressIndicator()
    );
  }

  /// 設定項目リスト
  Widget _configurationList() {
    return ListView(
      children: [
        if (!Configure.instance.hideAd)
          const AdBannerWidget(),
        if (!Configure.instance.hideAd)
          _adVisible(),
        _syncGoogleCalendar(),
      ],
    );
  }

  /// 広告非表示設定
  /// 既にアイテム購入済みの場合は表示しない
  Widget _adVisible() {
    return SwitchListTile(
        secondary: const Icon(Icons.hide_image),
        title: Text('広告を非表示にする', style: Theme.of(context).textTheme.titleLarge,),
        value: Configure.instance.hideAd,
        onChanged: (hideAd) async {
          if (!await _inAppPurchase.requestBuyConsumable(PurchaseProductType.hideAd)) {
            await ErrorDialog.show(context: context, detail: 'Google Storeとの通信に失敗しました');
          }
        }
    );
  }

  /// Googleカレンダー同期設定
  Widget _syncGoogleCalendar() {
    return SwitchListTile(
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
    );
  }
}