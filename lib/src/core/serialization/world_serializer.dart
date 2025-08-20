import 'dart:convert';
import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/nexus_world.dart';
import 'package:nexus/src/core/serialization/component_factory.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// A utility class to serialize and deserialize the entire state of a [NexusWorld].
class WorldSerializer {
  final ComponentFactoryRegistry factoryRegistry;

  WorldSerializer(this.factoryRegistry);

  /// Serializes the entire world into a JSON string.
  ///
  /// Only entities and their serializable components will be included.
  String toJson(NexusWorld world) {
    final Map<String, dynamic> worldData = {
      'entities': world.entities.values
          .map((entity) {
            final Map<String, dynamic> componentsData = {};
            for (final component in entity.allComponents) {
              if (component is SerializableComponent) {
                // Explicitly cast to SerializableComponent to access toJson().
                // This resolves the type ambiguity for the compiler.
                componentsData[component.runtimeType.toString()] =
                    (component as SerializableComponent).toJson();
              }
            }
            // Only include entities that have at least one serializable component.
            return componentsData.isNotEmpty ? componentsData : null;
          })
          .where((data) => data != null)
          .toList(),
    };
    return jsonEncode(worldData);
  }

  /// Deserializes a JSON string back into a [NexusWorld] instance.
  ///
  /// The [factoryRegistry] must have all necessary component factories registered.
  NexusWorld fromJson(String json) {
    final world = NexusWorld();
    final Map<String, dynamic> worldData = jsonDecode(json);

    final List<dynamic> entitiesData = worldData['entities'];

    for (final entityData in entitiesData) {
      final entity = Entity();
      final Map<String, dynamic> componentsData = entityData;

      for (final typeName in componentsData.keys) {
        final componentJson = componentsData[typeName];
        final component = factoryRegistry.create(typeName, componentJson);
        entity.add(component);
      }
      world.addEntity(entity);
    }
    return world;
  }
}
