import 'package:nexus/nexus.dart';

/// A marker component that signals to the [PersistenceSystem] that this
/// entity's serializable components should be saved to and loaded from storage.
class PersistenceComponent extends Component with SerializableComponent {
  /// A unique key used to identify this entity in the storage.
  /// For example, 'player_data', 'app_settings', etc.
  final String storageKey;

  PersistenceComponent(this.storageKey);

  factory PersistenceComponent.fromJson(Map<String, dynamic> json) {
    return PersistenceComponent(json['storageKey'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {'storageKey': storageKey};

  @override
  List<Object?> get props => [storageKey];
}
