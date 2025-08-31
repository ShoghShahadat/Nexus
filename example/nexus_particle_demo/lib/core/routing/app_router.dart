import 'package:go_router/go_router.dart';
import 'package:nexus_particle_demo/features/particle_scene/presentation/routes/particle_scene_route.dart';

/// Manages the application's routes using GoRouter.
/// مسیرهای برنامه را با استفاده از GoRouter مدیریت می‌کند.
class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        // The main route for our particle scene.
        // مسیر اصلی برای صحنه ذرات ما.
        ParticleSceneRoute(),
      ],
    );
  }
}
