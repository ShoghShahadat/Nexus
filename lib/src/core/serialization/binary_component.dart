import 'package:nexus/nexus.dart';
import 'binary_reader_writer.dart';

/// An abstract mixin that defines the contract for a component that can be
/// serialized to and from a compact binary format.
///
/// This approach avoids code generation (build_runner) in favor of a clear,
/// manually implemented contract, providing stability and full control to the developer.
mixin BinaryComponent on Component {
  /// A unique integer identifier for this component type.
  /// This ID is used to identify the component type in the binary data stream.
  ///
  /// **IMPORTANT**: This ID must be unique across all BinaryComponent types.
  int get typeId;

  /// Serializes the component's data into a binary format using the [writer].
  void toBinary(BinaryWriter writer);

  /// Deserializes the component's data from a binary format using the [reader].
  void fromBinary(BinaryReader reader);
}
