import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/utils/frequency.dart';

// --- Spawning ---

/// A logic-only component for spawning new entities.
/// This component is NOT serializable because it contains functions.
class SpawnerComponent extends Component {
  /// A factory function that creates a new entity instance (a "prefab").
  final Entity Function() prefab;

  Frequency frequency;
  double cooldown;
  bool wantsToFire;

  /// An optional condition that must return true for spawning to occur.
  /// یک شرط اختیاری که برای رخ دادن ساخت، باید true برگرداند.
  final bool Function()? condition;

  SpawnerComponent({
    required this.prefab,
    this.frequency = Frequency.never,
    this.cooldown = 0.0,
    this.wantsToFire = false,
    this.condition,
  });

  @override
  List<Object?> get props =>
      [prefab, frequency, cooldown, wantsToFire, condition];
}

// --- Targeting & Movement ---

/// A serializable component that makes an entity seek a target.
class TargetingComponent extends Component with SerializableComponent {
  final EntityId targetId;
  final double turnSpeed; // Radians per second

  TargetingComponent({required this.targetId, this.turnSpeed = 2.0});

  factory TargetingComponent.fromJson(Map<String, dynamic> json) {
    return TargetingComponent(
      targetId: json['targetId'] as EntityId,
      turnSpeed: (json['turnSpeed'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {'targetId': targetId, 'turnSpeed': turnSpeed};

  @override
  List<Object?> get props => [targetId, turnSpeed];
}

// --- Collision & Physics ---

/// Defines the physical shape for collision detection.
enum CollisionShape { circle }

/// A serializable component that gives an entity a physical presence for collision detection.
class CollisionComponent extends Component with SerializableComponent {
  final CollisionShape shape;
  final double radius;
  final Set<String> collidesWith;
  final String tag;

  CollisionComponent({
    required this.tag,
    this.shape = CollisionShape.circle,
    this.radius = 10.0,
    Set<String>? collidesWith,
  }) : collidesWith = collidesWith ?? {};

  factory CollisionComponent.fromJson(Map<String, dynamic> json) {
    return CollisionComponent(
      shape: CollisionShape.values[json['shape'] as int],
      radius: (json['radius'] as num).toDouble(),
      collidesWith: (json['collidesWith'] as List).cast<String>().toSet(),
      tag: json['tag'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'shape': shape.index,
        'radius': radius,
        'collidesWith': collidesWith.toList(),
        'tag': tag,
      };

  @override
  List<Object?> get props => [shape, radius, collidesWith, tag];
}

// --- Health & Damage ---

/// A serializable component that gives an entity health points.
class HealthComponent extends Component with SerializableComponent {
  final double currentHealth;
  final double maxHealth;

  HealthComponent({required this.maxHealth, double? currentHealth})
      : currentHealth = currentHealth ?? maxHealth;

  factory HealthComponent.fromJson(Map<String, dynamic> json) {
    return HealthComponent(
      currentHealth: (json['currentHealth'] as num).toDouble(),
      maxHealth: (json['maxHealth'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {'currentHealth': currentHealth, 'maxHealth': maxHealth};

  @override
  List<Object?> get props => [currentHealth, maxHealth];
}

/// A serializable component that defines how much damage an entity deals on collision.
class DamageComponent extends Component with SerializableComponent {
  final double damage;

  DamageComponent(this.damage);

  factory DamageComponent.fromJson(Map<String, dynamic> json) {
    return DamageComponent((json['damage'] as num).toDouble());
  }

  @override
  Map<String, dynamic> toJson() => {'damage': damage};

  @override
  List<Object?> get props => [damage];
}
