import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../components/meteor_component.dart';
// --- FIX: Removed obsolete import for the deleted component ---
// --- اصلاح: حذف ایمپورت منسوخ شده برای کامپوننت حذف شده ---

/// A system that periodically spawns meteors.
/// Now it's just a simple timer, as the prefab creation logic
/// has been moved to the world_provider for better organization.
/// سیستمی که به صورت دوره‌ای شهاب‌سنگ تولید می‌کند.
/// اکنون این یک تایمر ساده است، زیرا منطق ساخت prefab برای سازماندهی بهتر
/// به world_provider منتقل شده است.
class MeteorSpawnerSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system now finds the spawner entity by its tag.
    // این سیستم اکنون موجودیت spawner را با تگ آن پیدا می‌کند.
    return entity.get<TagsComponent>()?.hasTag('meteor_spawner') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    final spawner = entity.get<SpawnerComponent>();
    if (spawner == null)
      return; // Spawner might have been removed (e.g., on game over)

    // The core SpawnerSystem now handles the actual spawning logic.
    // This system's responsibility is now greatly reduced, which is good design.
    // We could even remove this system entirely and just use the SpawnerComponent
    // on its own, but we keep it for potential future logic (e.g., spawning
    // different waves of enemies).
    // سیستم اصلی SpawnerSystem اکنون منطق واقعی تولید را مدیریت می‌کند.
    // مسئولیت این سیستم بسیار کاهش یافته که طراحی خوبی است.
  }
}
