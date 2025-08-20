import 'package:nexus/nexus.dart';

// --- Spawning ---

/// A logic-only component for spawning new entities.
/// یک کامپوننت فقط-منطقی برای تولید موجودیت‌های جدید.
///
/// This component is NOT serializable because it contains a function.
/// این کامپوننت به دلیل داشتن تابع، سریالایزبل نیست.
class SpawnerComponent extends Component {
  /// A factory function that creates a new entity instance (a "prefab").
  /// یک تابع factory که یک نمونه موجودیت جدید ("prefab") ایجاد می‌کند.
  final Entity Function() prefab;
  // --- FIX: Made fireRate mutable to allow for dynamic difficulty ---
  // --- اصلاح: fireRate برای امکان سختی پویا، قابل تغییر شد ---
  double fireRate; // Shots per second
  double cooldown;
  bool wantsToFire;

  SpawnerComponent({
    required this.prefab,
    this.fireRate = 1.0,
    this.cooldown = 0.0,
    this.wantsToFire = false,
  });

  @override
  List<Object?> get props => [prefab, fireRate, cooldown, wantsToFire];
}

// --- Targeting & Movement ---

/// A serializable component that makes an entity seek a target.
/// یک کامپوننت سریالایزبل که باعث می‌شود یک موجودیت به دنبال یک هدف بگردد.
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
/// شکل فیزیکی را برای تشخیص برخورد تعریف می‌کند.
enum CollisionShape { circle }

/// A serializable component that gives an entity a physical presence for collision detection.
/// یک کامپوننت سریالایزبل که به یک موجودیت برای تشخیص برخورد، یک حضور فیزیکی می‌دهد.
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
/// یک کامپوننت سریالایزبل که به یک موجودیت "جان" می‌دهد.
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
/// یک کامپوننت سریالایزبل که میزان آسیب یک موجودیت در برخورد را تعریف می‌کند.
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
