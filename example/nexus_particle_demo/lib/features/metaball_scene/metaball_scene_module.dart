import 'package:nexus/nexus.dart';
import 'package:nexus_particle_demo/features/metaball_scene/domain/entities/metaball_scene_assembler.dart';
import 'package:nexus_particle_demo/features/metaball_scene/domain/systems/blob_systems.dart';

/// The main module for the metaball scene feature.
/// ماژول اصلی برای فیچر صحنه متابال.
class MetaballSceneModule extends NexusModule {
  @override
  List<EntityProvider> get entityProviders => [_SceneEntityProvider()];

  @override
  List<SystemProvider> get systemProviders => [_MetaballSystemProvider()];
}

/// A private entity provider that creates the initial entities for the scene
/// only after the screen size is known.
/// یک ارائه‌دهنده موجودیت خصوصی که موجودیت‌های اولیه را برای صحنه
/// تنها پس از مشخص شدن اندازه صفحه ایجاد می‌کند.
class _SceneEntityProvider implements EntityProvider {
  bool _isInitialized = false;

  @override
  void createEntities(NexusWorld world) {
    // *** FIX: Wait for the ScreenResizedEvent to ensure screen dimensions are available. ***
    // *** اصلاح: منتظر ScreenResizedEvent می‌مانیم تا از در دسترس بودن ابعاد صفحه اطمینان حاصل شود. ***
    world.eventBus.on<ScreenResizedEvent>((event) {
      if (_isInitialized) return;
      _isInitialized = true;

      final assembler = MetaballSceneAssembler(world);
      final entities = assembler.assemble();
      for (final entity in entities) {
        world.addEntity(entity);
      }
    });
  }
}

/// A concrete implementation of SystemProvider for the metaball scene.
/// یک پیاده‌سازی مشخص از SystemProvider برای صحنه متابال.
class _MetaballSystemProvider implements SystemProvider {
  @override
  List<System> get systems => [
        // Logical systems for the metaballs
        // سیستم‌های منطقی برای متابال‌ها
        BlobMovementSystem(),
        BlobVisualsSystem(), // *** NEW: System to sync visuals ***
        MetaballSystem(),

        // Core systems needed for any custom painting scene
        // سیستم‌های اصلی مورد نیاز برای هر صحنه نقاشی سفارشی
        PhysicsSystem(),
        CustomPaintingSystem(),
      ];
}
