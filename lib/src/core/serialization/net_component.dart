// GENERATED CODE - DO NOT MODIFY BY HAND

/// An annotation to mark a [Component] as network-serializable.
///
/// Components annotated with `@NetComponent` will have binary serialization
/// methods (`toBinary` and `fromBinary`) generated for them by the
/// `binary_builder`. This is essential for efficient network communication
/// in online games and applications.
class NetComponent {
  /// A unique integer identifier for this component type.
  ///
  /// This ID is used to identify the component type in the binary data stream,
  /// making the payload smaller than using a string name.
  ///
  /// **IMPORTANT**: This ID must be unique across all NetComponent types
  /// in your project.
  final int typeId;

  const NetComponent(this.typeId);
}
