/// An abstract interface for storage adapters.
///
/// This allows the [PersistenceSystem] to be decoupled from the actual
/// storage mechanism (e.g., SharedPreferences, Hive, a remote database).
abstract class StorageAdapter {
  /// Saves a map of data with the given key.
  Future<void> save(String key, Map<String, dynamic> data);

  /// Loads a map of data for the given key.
  Future<Map<String, dynamic>?> load(String key);

  /// Loads all data from the storage.
  Future<Map<String, Map<String, dynamic>>> loadAll();

  /// Initializes the storage adapter.
  Future<void> init();
}
