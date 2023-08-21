import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paid_vacation_manager/repository/repository.dart';

/// 端末のストレージに対して読み書きを実施するクラス
class DeviceStorage implements Repository {
  /// 全件読み込み
  @override
  Future<Map<String, String>> readAll()
      => const FlutterSecureStorage().readAll();

  /// 読み込み
  @override
  Future<String?> read(final String key)
      => const FlutterSecureStorage().read(key: key);

  /// 書き込み
  @override
  Future<void> write({required final String key, required final String value})
      => const FlutterSecureStorage().write(key: key, value: value);

  /// 削除
  @override
  Future<void> delete(final String key)
      => const FlutterSecureStorage().delete(key: key);

  /// 全削除
  @override
  Future<void> deleteAll()
      => const FlutterSecureStorage().deleteAll();
}