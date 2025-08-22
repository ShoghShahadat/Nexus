import 'package:nexus/nexus.dart';

// --- Spawning ---

class SpawnerComponent extends Component {
  final Entity Function() prefab;
  Frequency frequency;
  double cooldown;
  bool wantsToFire;
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

class TargetingComponent extends Component
    with SerializableComponent, BinaryComponent {
  late EntityId targetId;
  late double turnSpeed;

  // FIX: Added a default constructor for the factory
  TargetingComponent({EntityId? targetId, double? turnSpeed})
      : targetId = targetId ?? -1,
        turnSpeed = turnSpeed ?? 2.0;

  @override
  int get typeId => 10;

  @override
  void fromBinary(BinaryReader reader) {
    targetId = reader.readInt32();
    turnSpeed = reader.readDouble();
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeInt32(targetId);
    writer.writeDouble(turnSpeed);
  }

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

enum CollisionShape { circle }

class CollisionComponent extends Component
    with SerializableComponent, BinaryComponent {
  late CollisionShape shape;
  late double radius;
  late Set<String> collidesWith;
  late String tag;

  // FIX: Added a default constructor for the factory
  CollisionComponent(
      {String? tag,
      CollisionShape? shape,
      double? radius,
      Set<String>? collidesWith})
      : tag = tag ?? '',
        shape = shape ?? CollisionShape.circle,
        radius = radius ?? 10.0,
        collidesWith = collidesWith ?? {};

  @override
  int get typeId => 8;

  @override
  void fromBinary(BinaryReader reader) {
    tag = reader.readString();
    shape = CollisionShape.values[reader.readInt32()];
    radius = reader.readDouble();
    final count = reader.readInt32();
    collidesWith.clear();
    for (int i = 0; i < count; i++) {
      collidesWith.add(reader.readString());
    }
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeString(tag);
    writer.writeInt32(shape.index);
    writer.writeDouble(radius);
    writer.writeInt32(collidesWith.length);
    for (final tag in collidesWith) {
      writer.writeString(tag);
    }
  }

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

class HealthComponent extends Component
    with SerializableComponent, BinaryComponent {
  late double currentHealth;
  late double maxHealth;

  // FIX: Added a default constructor for the factory
  HealthComponent({double? maxHealth, double? currentHealth})
      : maxHealth = maxHealth ?? 100.0,
        currentHealth = currentHealth ?? maxHealth ?? 100.0;

  @override
  int get typeId => 3;

  @override
  void fromBinary(BinaryReader reader) {
    currentHealth = reader.readDouble();
    // maxHealth is considered static and not sent over the network to save bandwidth
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeDouble(currentHealth);
  }

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

class DamageComponent extends Component
    with SerializableComponent, BinaryComponent {
  late double damage;

  // FIX: Added a default constructor for the factory
  DamageComponent([this.damage = 0.0]);

  @override
  int get typeId => 9;

  @override
  void fromBinary(BinaryReader reader) {
    damage = reader.readDouble();
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeDouble(damage);
  }

  factory DamageComponent.fromJson(Map<String, dynamic> json) {
    return DamageComponent((json['damage'] as num).toDouble());
  }

  @override
  Map<String, dynamic> toJson() => {'damage': damage};

  @override
  List<Object?> get props => [damage];
}
