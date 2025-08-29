// FILE: packages/nexus/lib/src/systems/persistence_system.dart
// (English comments for code clarity)

import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/storage/storage_adapter.dart';
import 'package:flutter/foundation.dart';

// --- FINAL FIX: Core events are now defined and exported from the package itself ---
class SaveDataEvent {}

class DataLoadedEvent {}

/// A system that handles saving and loading entities with a [PersistenceComponent].
class PersistenceSystem extends System {
  StorageAdapter? _storage;
  bool _hasLoaded = false;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    world.eventBus.on<SaveDataEvent>(_handleSave);
  }

  @override
  Future<void> init() async {
    try {
      debugPrint(
          '[PersistenceSystem] Attempting to get StorageAdapter from GetIt...');
      _storage = services.get<StorageAdapter>();
      debugPrint('[PersistenceSystem] StorageAdapter retrieved successfully.');
      await _load();
    } on StateError catch (e) {
      debugPrint(
          '[PersistenceSystem] FATAL ERROR: Could not get StorageAdapter. Make sure it is registered in the isolateInitializer. Details: $e');
    } catch (e) {
      debugPrint(
          '[PersistenceSystem] An unexpected error occurred during init: $e');
    }
  }

  Future<void> _handleSave(SaveDataEvent event) async {
    if (_storage == null) return;
    final entitiesToSave =
        world.entities.values.where((e) => e.has<PersistenceComponent>());

    for (final entity in entitiesToSave) {
      final key = entity.get<PersistenceComponent>()!.storageKey;
      final entityJson = <String, dynamic>{};

      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          entityJson[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }
      await _storage!.save('nexus_$key', entityJson);
      debugPrint('💾 [PersistenceSystem] Saved data for key: $key');
    }
  }

  Future<void> _load() async {
    if (_storage == null || _hasLoaded) return;
    _hasLoaded = true;

    final allData = await _storage!.loadAll();
    if (allData.isEmpty) {
      debugPrint('[PersistenceSystem] No data to load from storage.');
      world.eventBus.fire(DataLoadedEvent());
      return;
    }

    debugPrint(
        '📂 [PersistenceSystem] Loading data for ${allData.length} keys: ${allData.keys}');

    for (final key in allData.keys) {
      final entityData = allData[key]!;
      var entity = world.entities.values.firstWhere(
          (e) => e.get<PersistenceComponent>()?.storageKey == key,
          orElse: () => Entity());

      for (final typeName in entityData.keys) {
        final componentJson = entityData[typeName]!;
        final component =
            ComponentFactoryRegistry.I.create(typeName, componentJson);
        entity.add(component);
      }

      if (!world.entities.containsKey(entity.id)) {
        world.addEntity(entity);
      }
    }
    debugPrint(
        '🏁 [PersistenceSystem] Data loading complete. Firing DataLoadedEvent.');
    world.eventBus.fire(DataLoadedEvent());
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
