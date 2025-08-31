import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/nexus_router.dart';
import 'package:nexus_particle_demo/features/particle_scene/particle_scene_module.dart';
import 'package:nexus_particle_demo/features/particle_scene/presentation/rendering/particle_rendering_system.dart';

/// A specialized GoRoute that sets up the Nexus world for the particle scene.
/// یک GoRoute تخصصی که دنیای Nexus را برای صحنه ذرات راه‌اندازی می‌کند.
class ParticleSceneRoute extends NexusRoute {
  ParticleSceneRoute()
      : super(
          path: '/',
          // This function runs in the background isolate.
          // این تابع در ایزولیت پس‌زمینه اجرا می‌شود.
          worldProvider: () {
            final world = NexusWorld();
            // Load all systems and entities for the particle scene.
            // تمام سیستم‌ها و موجودیت‌ها را برای صحنه ذرات بارگذاری می‌کند.
            world.loadModule(ParticleSceneModule());
            return world;
          },
          // This function runs on the main UI thread.
          // این تابع در ترد اصلی UI اجرا می‌شود.
          renderingSystemBuilder: (context) => ParticleRenderingSystem(),
        );
}
