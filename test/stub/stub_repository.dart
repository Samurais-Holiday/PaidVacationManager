import 'package:paid_vacation_manager/repository/repository.dart';

/// メモリにて永続化を模擬するスタブリポジトリ
class StubRepository implements Repository {
  final Map<String, String> _keyToValue;

  /// コンストラクタ
  StubRepository() : _keyToValue = {};

  @override
  Future<void> delete(String key) async => _keyToValue.remove(key);

  @override
  Future<void> deleteAll() async => _keyToValue.clear();

  @override
  Future<String?> read(String key) async => _keyToValue[key];

  @override
  Future<Map<String, String>> readAll() async => _keyToValue;

  @override
  Future<void> write({required String key, required String value}) async => _keyToValue[key] = value;
}