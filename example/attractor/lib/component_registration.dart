import 'package:nexus/nexus.dart';
import 'components/debug_info_component.dart';
import 'components/health_orb_component.dart';
import 'components/meteor_component.dart';
import 'components/network_components.dart';
import 'components/network_id_component.dart'; // <-- Import the new component

/// A centralized function to register all custom and binary components.
/// This ensures that components are registered before any world is created.
void registerAllComponents() {
  // --- JSON Components ---
  final customJsonComponents = <String, ComponentFactory>{
    'DebugInfoComponent': (json) => DebugInfoComponent.fromJson(json),
    'MeteorComponent': (json) => MeteorComponent.fromJson(json),
    'HealthOrbComponent': (json) => HealthOrbComponent.fromJson(json),
  };
  ComponentFactoryRegistry.I.registerAll(customJsonComponents);

  // --- Binary (Network) Components ---
  final factory = BinaryComponentFactory.I;
  factory.register(1, () => PositionComponent());
  factory.register(2, () => PlayerComponent());
  factory.register(3, () => HealthComponent());
  factory.register(4, () => VelocityComponent());
  factory.register(5, () => TagsComponent());
  factory.register(6, () => MeteorComponent());
  factory.register(7, () => HealthOrbComponent());
  factory.register(8, () => CollisionComponent());
  factory.register(9, () => DamageComponent());
  factory.register(10, () => TargetingComponent());
  factory.register(
      11, () => NetworkIdComponent()); // <-- Register the new component
}
