import 'package:nexus/nexus.dart';
import 'binary_component.dart';
import 'binary_reader_writer.dart';

/// A function signature for a factory that creates an empty instance of a
/// [BinaryComponent].
typedef BinaryComponentCreator = BinaryComponent Function();

/// A registry for mapping component type IDs to their binary creator functions.
class BinaryComponentFactory {
  final Map<int, BinaryComponentCreator> _creators = {};

  static final BinaryComponentFactory I = BinaryComponentFactory._internal();
  BinaryComponentFactory._internal();

  /// Registers a component creator for a given type ID.
  /// This is called once at startup for each network-enabled component.
  void register(int typeId, BinaryComponentCreator creator) {
    if (_creators.containsKey(typeId)) {
      print(
          'WARNING: A binary component creator for typeId $typeId is already registered. Overwriting.');
    }
    _creators[typeId] = creator;
  }

  /// Creates an empty component instance from its type ID.
  BinaryComponent create(int typeId) {
    final creator = _creators[typeId];
    if (creator == null) {
      throw Exception(
          'No binary creator registered for component type ID "$typeId". '
          'Ensure you call BinaryComponentFactory.I.register() for all '
          'BinaryComponent types at the start of your application.');
    }
    return creator();
  }
}
