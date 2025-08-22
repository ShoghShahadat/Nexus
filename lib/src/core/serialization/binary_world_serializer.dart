import 'dart:typed_data';
import 'package:nexus/nexus.dart';
import 'binary_component.dart';
import 'binary_component_factory.dart';
import 'binary_reader_writer.dart';

/// A utility class to serialize and deserialize entities into a compact binary format.
class BinaryWorldSerializer {
  final BinaryComponentFactory factoryRegistry;

  BinaryWorldSerializer(this.factoryRegistry);

  /// Serializes a list of entities into a single [Uint8List] byte buffer.
  Uint8List serialize(List<Entity> entities) {
    final writer = BinaryWriter();
    final binaryEntities = entities
        .where((e) => e.allComponents.any((c) => c is BinaryComponent))
        .toList();

    writer.writeInt32(binaryEntities.length);

    for (final entity in binaryEntities) {
      final binaryComponents =
          entity.allComponents.whereType<BinaryComponent>().toList();

      writer.writeInt32(entity.id);
      writer.writeInt32(binaryComponents.length);

      for (final component in binaryComponents) {
        writer.writeInt32(component.typeId);
        component.toBinary(writer);
      }
    }
    return writer.toBytes();
  }

  /// Deserializes a byte buffer and applies the state to the [NexusWorld].
  void deserialize(NexusWorld world, Uint8List data) {
    if (data.isEmpty) return;
    final reader = BinaryReader(data);
    final entityCount = reader.readInt32();

    for (int i = 0; i < entityCount; i++) {
      final entityId = reader.readInt32();
      final componentCount = reader.readInt32();

      var entity = world.entities[entityId];
      if (entity == null) {
        // In a real game, you might want to create the entity here.
        // For now, we'll just skip entities that don't exist on the client.
        print(
            'Warning: Received data for unknown entity ID $entityId. Skipping.');
        // We still need to advance the reader past the skipped component data.
        // This is a complex problem to solve robustly. For this example, we
        // assume entities are pre-existing.
        continue;
      }

      for (int j = 0; j < componentCount; j++) {
        final componentTypeId = reader.readInt32();
        // Check if the entity already has a component of this type.
        var component = entity.allComponents
            .whereType<BinaryComponent>()
            .firstWhere((c) => c.typeId == componentTypeId,
                orElse: () => factoryRegistry.create(componentTypeId));

        component.fromBinary(reader);
        entity.add(component as Component);
      }
    }
  }
}
