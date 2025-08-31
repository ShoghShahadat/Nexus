import 'package:nexus/nexus.dart';
import 'package:nexus_particle_demo/features/particle_scene/domain/entities/particle_scene_assembler.dart';
import 'package:nexus_particle_demo/features/particle_scene/domain/systems/particle_visual_systems.dart';

/// The NexusModule that defines the entire particle scene feature.
/// ماژول Nexus که تمام قابلیت صحنه ذرات را تعریف می‌کند.
class ParticleSceneModule extends NexusModule {
  @override
  List<SystemProvider> get systemProviders => [
        _LogicSystemsProvider(),
      ];

  @override
  List<EntityProvider> get entityProviders => [
        _SceneEntityProvider(),
      ];
}

/// A provider for all the systems needed for the particle simulation logic.
/// یک تأمین‌کننده برای تمام سیستم‌های مورد نیاز برای منطق شبیه‌سازی ذرات.
class _LogicSystemsProvider implements SystemProvider {
  @override
  List<System> get systems => [
        // *** MODIFIED: Use the new project-specific spawner ***
        // *** اصلاح: استفاده از تولیدکننده جدید مخصوص پروژه ***
        ProjectParticleSpawningSystem(),

        // Manages the aging of particles (no longer removes them, LifecyclePolicy does).
        // عمر ذرات را مدیریت می‌کند (دیگر آن‌ها را حذف نمی‌کند، LifecyclePolicy این کار را انجام می‌دهد).
        ParticleLifecycleSystem(),

        // Applies velocity to position for movement.
        // سرعت را برای حرکت به موقعیت اعمال می‌کند.
        PhysicsSystem(),

        // Listens for pointer events and moves the attractor entity.
        // به رویدادهای اشاره‌گر گوش داده و موجودیت جاذب را حرکت می‌دهد.
        PointerSystem(),

        // Applies a gravitational pull from the attractor to all particles.
        // یک کشش گرانشی از جاذب به تمام ذرات اعمال می‌کند.
        AttractionSystem(),

        // *** NEW: The system that translates logic to visuals ***
        // *** جدید: سیستمی که منطق را به بصریات ترجمه می‌کند ***
        ParticleVisualsSystem(),

        // Collects all drawable entities and creates a serializable render packet.
        // تمام موجودیت‌های قابل ترسیم را جمع‌آوری کرده و یک بسته رندر سریالایزبل ایجاد می‌کند.
        CustomPaintingSystem(),
      ];
}

/// A provider that creates the initial static entities for the scene.
/// یک تأمین‌کننده که موجودیت‌های استاتیک اولیه را برای صحنه ایجاد می‌کند.
class _SceneEntityProvider implements EntityProvider {
  @override
  void createEntities(NexusWorld world) {
    final assembler = ParticleSceneAssembler(world);
    for (final entity in assembler.assemble()) {
      world.addEntity(entity);
    }
  }
}
