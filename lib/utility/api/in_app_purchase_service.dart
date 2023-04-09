import 'dart:async';
import 'dart:developer';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:paid_vacation_manager/enum/purchase_item.dart';

/// アプリ内購入に関する機能を提供するクラス
class InAppPurchaseService {
  /// アプリ内購入アイテム情報
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  /// アプリ内購入アイテムID変換テーブル
  static final Map<PurchaseProductType, String> productTypeToString = {
    PurchaseProductType.hideAd: 'delete_ad',
  };

  /// コンストラクタ
  InAppPurchaseService({void Function(PurchaseDetails)? onCompleted,
      void Function(PurchaseDetails)? onPending, void Function(PurchaseDetails)? onError}) {
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdate(purchaseDetailsList,
          onCompleted: onCompleted, onPending: onPending, onError: onError);
    }, onDone: () {
      _subscription.cancel();
    });
  }

  /// _subscriptionの状態変更時のコールバック関数
  Future<void> _listenToPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList,
      {void Function(PurchaseDetails)? onCompleted, void Function(PurchaseDetails)? onPending, void Function(PurchaseDetails)? onError}) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased
          || purchaseDetails.status == PurchaseStatus.restored) {
        onCompleted?.call(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.pending) {
        onPending?.call(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        onError?.call(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  /// 広告削除アイテム購入
  /// アイテムの表示に成功した場合true, 失敗した場合falseを返却
  Future<bool> requestBuyConsumable(PurchaseProductType item) async {
    assert(productTypeToString.containsKey(item));

    if (!await InAppPurchase.instance.isAvailable()) {
      log('InAppPurchase is not available.');
      return false;
    }
    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({ productTypeToString[item]! });
    if (response.productDetails.isEmpty) {
      log('Purchase id "${productTypeToString[item]}" is not found.');
      return false;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    return await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
  }
}