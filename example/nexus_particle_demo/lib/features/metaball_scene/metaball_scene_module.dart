import 'package:nexus/nexus.dart';
import 'package:nexus_particle_demo/features/metaball_scene/domain/systems/blob_systems.dart';

/// The main module for the metaball scene feature.
/// ماژول اصلی برای فیچر صحنه متابال.
class MetaballSceneModule extends NexusModule {
  @override
  List<EntityProvider> get entityProviders =>
      []; // Entities are now created by a system

  @override
  List<SystemProvider> get systemProviders => [_MetaballSystemProvider()];
}

/// A concrete implementation of SystemProvider for the metaball scene.
/// یک پیاده‌سازی مشخص از SystemProvider برای صحنه متابال.
class _MetaballSystemProvider implements SystemProvider {
  @override
  List<System> get systems => [
        // --- NEW & REWRITTEN SYSTEMS ---
        MetaballSceneSetupSystem(), // Initializes the scene once.
        DropletPhysicsSystem(), // Handles gravity, collisions, and merging.
        MetaballSystem(), // Handles the visual metaball effect.

        // Core systems needed for any custom painting scene
        // سیستم‌های اصلی مورد نیاز برای هر صحنه نقاشی سفارشی
        PhysicsSystem(),
        CustomPaintingSystem(),

        // Core system that updates screen info.
        // سیستمی که اطلاعات صفحه را به‌روز می‌کند.
        ResponsivenessSystem(),
      ];
}
