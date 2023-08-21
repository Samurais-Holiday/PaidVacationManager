/// リポジトリのインターフェース定義クラス
abstract class Repository {
  /// 全件読み込み
  Future<Map<String, String>> readAll();
  /// 読み込み
  Future<String?> read(final String key);
  /// 書き込み
  Future<void> write({required final String key, required final String value});
  /// 削除
  Future<void> delete(final String key);
  /// 全削除
  Future<void> deleteAll();
}