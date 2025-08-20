/// A contract for components that can be converted to and from JSON.
///
/// By implementing this mixin, a component declares that it can be safely
/// serialized for persistence or network transfer. This is the foundation for
/// features like saving game state or multiplayer synchronization.
///
/// Implementers must provide a `toJson` method and a corresponding
/// `fromJson` factory constructor.
mixin SerializableComponent {
  /// Converts this component instance to a JSON map.
  Map<String, dynamic> toJson();
}
