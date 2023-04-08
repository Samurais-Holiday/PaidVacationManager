import 'dart:async';
import 'dart:developer';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:paid_vacation_manager/config/configure.dart';
import 'package:paid_vacation_manager/utility/api/local_storage_manager.dart';

/// アプリ内購入に関する機能を提供するクラス
class InAppPurchaseService {
  /// シングルトンインスタンス
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  /// アプリ内購入アイテム情報
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  /// 広告削除アイテムID
  static const String _hideAdId = 'delete_ad';

  /// プライベートコンストラクタ
  InAppPurchaseService._internal() {
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdate(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    });
  }

  /// _subscriptionの状態変更時のコールバック関数
  Future<void> _listenToPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased
          || purchaseDetails.status == PurchaseStatus.restored) {
        await _deliverProduct(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  /// 購入したアイテムの機能を提供する
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    switch (purchaseDetails.productID) {
      case _hideAdId:
        await LocalStorageManager.writeHideAd(true);
        await Configure.instance.load();
        break;
    }
  }

  /// シングルトンインスタンス取得
  static InAppPurchaseService get instance => _instance;

  /// 広告削除アイテム購入
  /// 購入に成功した場合true, 失敗した場合falseを返却
  Future<bool> buyHideAd() async {
    if (!await InAppPurchase.instance.isAvailable()) {
      log('InAppPurchase is not available.');
      return false;
    }
    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(<String>{_hideAdId});
    if (response.productDetails.isEmpty) {
      log('Purchase identifier "$_hideAdId" is not found.');
      return false;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    return await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
  }
}