import 'package:nexus/nexus.dart';

/// An event fired by the `CollisionSystem` when two entities collide.
/// رویدادی که توسط `CollisionSystem` هنگام برخورد دو موجودیت منتشر می‌شود.
///
/// Systems like `DamageSystem` can listen for this event to apply effects.
/// سیستم‌هایی مانند `DamageSystem` می‌توانند برای اعمال افکت‌ها به این رویداد گوش دهند.
class CollisionEvent {
  final EntityId entityA;
  final EntityId entityB;

  CollisionEvent(this.entityA, this.entityB);
}

/// An event that can be fired to signal that an entity with a SpawnerComponent
/// should perform a single shot.
/// رویدادی که می‌توان برای سیگنال دادن به یک موجودیت دارای SpawnerComponent
/// جهت انجام یک شلیک تکی، منتشر کرد.
class FireEvent {
  final EntityId spawnerId;

  FireEvent(this.spawnerId);
}
