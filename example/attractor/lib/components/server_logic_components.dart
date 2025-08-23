// ==============================================================================
// File: lib/components/server_logic_components.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: New file containing client-side versions of components that
//              were previously server-only, needed for the new client-authoritative model.
// ==============================================================================

import 'package:nexus/nexus.dart';

/// A component that defines the spawning behavior for an entity.
/// This is now managed entirely on the client.
class SpawnerComponent extends Component {
  final Entity Function() prefab;
  double frequency; // Events per second
  double cooldown;
  final bool Function()? condition;

  SpawnerComponent({
    required this.prefab,
    this.frequency = 1.0,
    this.cooldown = 0.0,
    this.condition,
  });

  @override
  List<Object?> get props => [prefab, frequency, cooldown, condition];
}

/// A component that tracks the age and lifespan of an entity.
/// Used for meteor lifecycle management on the client.
class LifecycleComponent extends Component {
  double age;
  final double maxAge;
  final double initialSpeed;
  final double initialWidth;
  final double initialHeight;

  LifecycleComponent({
    this.age = 0.0,
    required this.maxAge,
    required this.initialSpeed,
    required this.initialWidth,
    required this.initialHeight,
  });

  @override
  List<Object?> get props =>
      [age, maxAge, initialSpeed, initialWidth, initialHeight];
}

/// A marker component added to entities that are owned and simulated
/// by this client instance. The NetworkSystem uses this to know which
/// entities to send to the server.
class OwnedComponent extends Component {
  @override
  List<Object?> get props => [];
}
