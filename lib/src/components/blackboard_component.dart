import 'package:nexus/nexus.dart';

/// A flexible, serializable, key-value data store for an entity.
///
/// The Blackboard acts as a dynamic "memory" for an entity, allowing systems
/// to read and write arbitrary data without needing to define a new component
/// for every single property. It's particularly useful for AI and complex state management.
class BlackboardComponent extends Component with SerializableComponent {
  final Map<String, dynamic> _data;

  BlackboardComponent([Map<String, dynamic>? initialData])
      : _data = initialData ?? {};

  /// Retrieves a value from the blackboard with a specific type.
  /// Returns null if the key doesn't exist or the type is wrong.
  T? get<T>(String key) {
    final value = _data[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Sets or updates a value on the blackboard.
  void set(String key, dynamic value) {
    _data[key] = value;
  }

  /// Checks if the blackboard contains a specific key.
  bool has(String key) {
    return _data.containsKey(key);
  }

  /// Removes a key-value pair from the blackboard.
  void remove(String key) {
    _data.remove(key);
  }

  /// Increments a numeric value on the blackboard.
  /// If the key doesn't exist, it's initialized to the given amount.
  void increment(String key, [num amount = 1]) {
    final currentValue = get<num>(key) ?? 0;
    set(key, currentValue + amount);
  }

  /// Toggles a boolean value on the blackboard.
  /// If the key doesn't exist, it's initialized to `true`.
  void toggle(String key) {
    final currentValue = get<bool>(key) ?? false;
    set(key, !currentValue);
  }

  factory BlackboardComponent.fromJson(Map<String, dynamic> json) {
    return BlackboardComponent(Map<String, dynamic>.from(json['data']));
  }

  @override
  Map<String, dynamic> toJson() => {'data': _data};

  @override
  List<Object?> get props => [_data];
}
