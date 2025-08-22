import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import 'binary_component_factory.dart';
import 'binary_reader_writer.dart';
import 'net_component.dart';

// A generated part file will be created here by the build_runner.
// This file will contain the implementations of `toBinary` for each
// `@NetComponent` and a registration function.
part 'binary_world_serializer.g.dart';

/// A utility class to serialize and deserialize the state of entities
/// into a compact binary format for network transmission.
class BinaryWorldSerializer {
  final BinaryComponentFactory factoryRegistry;

  BinaryWorldSerializer(this.factoryRegistry);

  /// Serializes a list of entities into a single [Uint8List] byte buffer.
  ///
  /// The format is:
  /// [EntityCount (int32)]
  ///   [EntityID (int32)]
  ///   [ComponentCount (int32)]
  ///     [ComponentTypeID (int32)]
  ///     [...component data...]
  ///     [ComponentTypeID (int32)]
  ///     [...component data...]
  ///   [EntityID (int32)]
  ///   ...
  Uint8List serialize(List<Entity> entities) {
    final writer = BinaryWriter();
    writer.writeInt32(entities.length);

    for (final entity in entities) {
      final netComponents = entity.allComponents
          .where((c) =>
              c.runtimeType.toString() !=
              'Component') // Filter out base Component
          .toList();

      writer.writeInt32(entity.id);
      writer.writeInt32(netComponents.length);

      for (final component in netComponents) {
        // This will call the generated extension method.
        // The `as dynamic` is a common workaround to call extension methods
        // on a variable with a less specific type.
        (component as dynamic).toBinary(writer);
      }
    }
    return writer.toBytes();
  }

  /// Deserializes a byte buffer into a list of entities and applies
  /// their state to the provided [NexusWorld].
  ///
  /// If an entity from the payload already exists in the world, its
  /// components are updated. If not, a new entity is created.
  void deserialize(NexusWorld world, Uint8List data) {
    final reader = BinaryReader(data);
    final entityCount = reader.readInt32();

    for (int i = 0; i < entityCount; i++) {
      final entityId = reader.readInt32();
      final componentCount = reader.readInt32();

      // Find an existing entity or create a new one.
      // Note: This assumes entity IDs are managed consistently between client/server.
      var entity = world.entities[entityId];
      if (entity == null) {
        // This is a simplified approach. A real-world scenario might need
        // a more robust way to handle newly appearing entities.
        print(
            "Warning: Deserializing new entity with ID $entityId. This is not fully supported yet.");
        continue; // Skip for now
      }

      for (int j = 0; j < componentCount; j++) {
        final componentTypeId = reader.readInt32();
        final component = factoryRegistry.create(componentTypeId, reader);
        entity.add(component);
      }
    }
  }
}
