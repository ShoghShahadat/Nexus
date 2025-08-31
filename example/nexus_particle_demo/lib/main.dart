import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_particle_demo/core/services/di_container.dart' as di;
import 'package:nexus_particle_demo/features/metaball_scene/metaball_scene_module.dart';
import 'package:nexus_particle_demo/features/scene_renderer/scene_rendering_system.dart';

/// The main entry point of the application.
/// نقطه ورود اصلی برنامه.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  di.setupDI();
  runApp(const MyApp());
}

/// The root widget of the application that manages the lifecycle of the
/// rendering system to ensure it survives hot reloads.
/// ویجت ریشه برنامه که چرخه حیات سیستم رندرینگ را مدیریت می‌کند
/// تا اطمینان حاصل شود که در طول Hot Reload زنده می‌ماند.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SceneRenderingSystem _renderingSystem;

  @override
  void initState() {
    super.initState();
    // Create the rendering system once.
    // سیستم رندرینگ را یک بار ایجاد می‌کنیم.
    _renderingSystem = SceneRenderingSystem(
      // --- AESTHETIC UPGRADE: Changed background color for a better mood ---
      // --- ارتقاء ظاهری: تغییر رنگ پس‌زمینه برای ایجاد حس بهتر ---
      backgroundColor:
          const Color(0xFF2C3E50), // A dark, atmospheric slate blue
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Metaball Demo',
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: NexusWidget(
        worldProvider: () {
          final world = NexusWorld();
          world.loadModule(MetaballSceneModule());
          return world;
        },
        renderingSystem: _renderingSystem,
      ),
    );
  }
}
