import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

/// Googleサインインの機能を提供するクラス
class GoogleSignInManager {
  /// インスタンス生成不可
  GoogleSignInManager._internal();

  /// Googleアカウント認証用変数
  static GoogleSignIn _googleSignIn = GoogleSignIn();
  static GoogleSignInAccount? _signedInAccount;
  GoogleSignInAccount? get signedInAccount => _signedInAccount;

  /// Googleアカウントにサインインする
  static Future<bool> signInGoogle({required List<String> scope}) async {
    _googleSignIn = GoogleSignIn(scopes: scope);
    final isSignedIn = await _googleSignIn.isSignedIn();
    _signedInAccount = (isSignedIn)
        ? await _googleSignIn.signInSilently()  // サインイン済みの場合はポップアップを出さずにサインインする
        : await _googleSignIn.signIn();

    if (_signedInAccount != null) {
      // 認証に成功した場合
      log('サインイン成功');
      return true;
    } else {
      // 認証に失敗した場合
      if (isSignedIn) {
        _googleSignIn.disconnect(); // 認証情報を初期化
      }
      log('$signInGoogle\nサインインに失敗しました');
      return false;
    }
  }

  /// サインイン済みか
  static Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  /// 認証情報を初期化する
  static Future signOut() => _googleSignIn.signOut();

  /// 認証済みのHTTPクライアントを取得する
  static Future<AuthClient?> get authenticatedClient => _googleSignIn.authenticatedClient();
}