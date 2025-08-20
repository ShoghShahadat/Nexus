import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/app_lifecycle_component.dart';
import 'package:nexus/src/events/app_lifecycle_event.dart';

/// A system that manages the application's lifecycle state.
/// سیستمی که وضعیت چرخه حیات برنامه را مدیریت می‌کند.
///
/// It listens for `AppLifecycleEvent`s from the UI thread and updates a central
/// entity's `AppLifecycleComponent`.
/// این سیستم به رویدادهای `AppLifecycleEvent` از ترد UI گوش می‌دهد و
/// `AppLifecycleComponent` یک موجودیت مرکزی را به‌روزرسانی می‌کند.
class AppLifecycleSystem extends System {
  static const String _worldStateTag = 'world_state';

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _ensureWorldStateEntity();
    world.eventBus.on<AppLifecycleEvent>(_onLifecycleChange);
  }

  void _ensureWorldStateEntity() {
    // Check if the entity already exists.
    // بررسی می‌کند که آیا موجودیت از قبل وجود دارد یا خیر.
    final existing = world.entities.values
        .where((e) => e.get<TagsComponent>()?.hasTag(_worldStateTag) ?? false);

    if (existing.isEmpty) {
      // Create a dedicated entity to hold the world state if it doesn't exist.
      // یک موجودیت اختصاصی برای نگهداری وضعیت دنیا ایجاد می‌کند.
      final worldStateEntity = Entity();
      worldStateEntity.add(TagsComponent({_worldStateTag}));
      worldStateEntity.add(AppLifecycleComponent(AppLifecycleStatus.resumed));
      world.addEntity(worldStateEntity);
    }
  }

  void _onLifecycleChange(AppLifecycleEvent event) {
    try {
      final worldStateEntity = world.entities.values.firstWhere(
          (e) => e.get<TagsComponent>()?.hasTag(_worldStateTag) ?? false);

      worldStateEntity.add(AppLifecycleComponent(event.status));
    } catch (e) {
      print(
          '[AppLifecycleSystem] Error: Could not find the world_state entity to update lifecycle status.');
    }
  }

  @override
  bool matches(Entity entity) => false; // This system is purely event-driven.

  @override
  void update(Entity entity, double dt) {
    // Logic is handled in the event listener.
    // منطق در شنونده رویداد مدیریت می‌شود.
  }
}
