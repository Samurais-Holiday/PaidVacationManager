import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../model/purchase_item.dart';
import '../model/settings.dart';
import '../utility/api/google_calendar.dart';
import '../utility/api/google_sign_in_manager.dart';
import '../utility/api/in_app_purchase_service.dart';
import '../utility/logger.dart';
import 'component/ad_banner.dart';
import 'component/dialogs.dart';

/// 設定画面
/// * TODO: 所定労働時間の設定
/// * TODO: 有効期間の設定
class SettingsPage extends StatefulWidget {
  /// 各種設定
  final Settings _settings;

  /// コンストラクタ
  const SettingsPage({required Settings settings, Key? key})
      : _settings = settings, super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// アプリ内購入機能
  late InAppPurchaseService _inAppPurchase;
  /// 処理中か
  bool _isPending;
  /// 広告削除の値段
  String? _hideAdPrice;

  /// コンストラクタ
  _SettingsPageState() : _isPending = false {
    _inAppPurchase = InAppPurchaseService(
      onCompleted: _deliverProduct,
      onPending: _showPending,
      onError: _showError,
    );
    _inAppPurchase.price(PurchaseProductType.hideAd).then((price) {
      setState(() {
        _hideAdPrice = price;
      });
    });
  }

  /// アイテム購入時処理
  void _deliverProduct(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.productID == InAppPurchaseService.productTypeToString[PurchaseProductType.hideAd]) {
      widget._settings.hideAd = true;
    }
    setState(() {
      _isPending = false;
    });
  }

  /// アイテム購入処理中処理
  void _showPending(PurchaseDetails purchaseDetails) {
    setState(() {
      _isPending = true;
    });
  }

  /// アイテム購入失敗時処理
  void _showError(PurchaseDetails purchaseDetails) {
    Dialogs.showError(context: context, text: '購入に失敗しました');
    setState(() {
      _isPending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
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
        if (!widget._settings.hideAd)
          const AdBannerWidget(),
        if (!widget._settings.hideAd)
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
        title: Text(
            '広告を非表示にする${_hideAdPrice != null ? ' ($_hideAdPrice)' : ''}',
            style: Theme.of(context).textTheme.titleLarge,
        ),
        value: widget._settings.hideAd,
        onChanged: (hideAd) {
          if (!hideAd) {
            return;
          }
          _inAppPurchase.requestBuyConsumable(PurchaseProductType.hideAd).then((bool isSuccess) {
            if (!isSuccess) {
              Dialogs.showError(context: context, text: 'Google Storeとの通信に失敗しました');
            }
          });
        }
    );
  }

  /// Googleカレンダー同期設定
  Widget _syncGoogleCalendar() {
    return SwitchListTile(
      secondary: const Icon(Icons.sync),
      title: Text('Googleカレンダーと同期', style: Theme.of(context).textTheme.titleLarge,),
      value: widget._settings.isSyncGoogleCalendar,
      onChanged: (bool isSync) async {
        // 値の設定
        setState(() {
          widget._settings.isSyncGoogleCalendar = isSync;
        });
        if (isSync) {
          // 同期設定をONにした場合、サインインを試みる
          if (!await GoogleSignInManager.signInGoogle(scope: [GoogleCalendar.calendarScope])) {
            Logger.info('Failed to sign in Google.');
            // 失敗したら同期設定OFFにする
            setState(() {
              widget._settings.isSyncGoogleCalendar = false;
            });
          }
        }
      },
    );
  }
}