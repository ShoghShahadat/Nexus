import 'package:nexus/nexus.dart';
import 'binary_reader_writer.dart';

/// A function signature for a factory that creates a [Component] from a
/// binary data stream using a [BinaryReader].
typedef BinaryComponentFactoryFunc = Component Function(BinaryReader reader);

/// A registry for mapping component type IDs to their binary deserialization factories.
///
/// This is a crucial part of the networking layer, allowing the system to
/// efficiently reconstruct components from a compact binary payload received

/// from the network.
class BinaryComponentFactory {
  final Map<int, BinaryComponentFactoryFunc> _factories = {};

  // Singleton instance for global access.
  static final BinaryComponentFactory I = BinaryComponentFactory._internal();

  BinaryComponentFactory._internal();

  /// Registers a single binary component factory.
  ///
  /// This method is typically called by an auto-generated function that
  /// registers all `@NetComponent` annotated components.
  void register(int typeId, BinaryComponentFactoryFunc factory) {
    if (_factories.containsKey(typeId)) {
      print(
          'WARNING: A binary component factory for typeId $typeId is already registered. Overwriting.');
    }
    _factories[typeId] = factory;
  }

  /// Creates a component instance from a binary reader by looking up its type ID.
  Component create(int typeId, BinaryReader reader) {
    final factory = _factories[typeId];
    if (factory == null) {
      throw Exception(
          'No binary factory registered for component type ID "$typeId". '
          'Ensure your generated `registerBinaryComponents()` function is called at startup.');
    }
    return factory(reader);
  }
}
