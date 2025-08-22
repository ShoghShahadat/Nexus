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

  /// Decodes a byte buffer into a map of server entity IDs to their components.
  /// This method does NOT modify the world; it only translates data.
  Map<int, List<Component>> decode(Uint8List data) {
    if (data.isEmpty) return {};
    final reader = BinaryReader(data);
    final entityCount = reader.readInt32();
    final Map<int, List<Component>> decodedWorld = {};

    for (int i = 0; i < entityCount; i++) {
      final entityId = reader.readInt32();
      final componentCount = reader.readInt32();
      final components = <Component>[];

      for (int j = 0; j < componentCount; j++) {
        final componentTypeId = reader.readInt32();
        final component = factoryRegistry.create(componentTypeId);
        component.fromBinary(reader);
        components.add(component as Component);
      }
      decodedWorld[entityId] = components;
    }
    return decodedWorld;
  }
}
