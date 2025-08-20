import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/dashboard_module.dart';
import 'package:nexus_example/dashboard_module/ui/widget_builders.dart';

/// The entry point for the background isolate.
/// This function creates and configures the NexusWorld.
NexusWorld provideDashboardWorld() {
  final world = NexusWorld();

  // Add core systems required by the module's animations.
  world.addSystem(AnimationSystem());
  world.addSystem(LifecycleSystem());

  // Load the entire dashboard feature as a self-contained module.
  world.loadModule(DashboardModule());

  return world;
}

/// The main entry point for the Flutter application.
void main() {
  // Register all core serializable components. This is crucial for
  // communication between the logic isolate and the UI thread.
  registerCoreComponents();
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configure the rendering system, which maps entity tags to widget builders.
    final renderingSystem = FlutterRenderingSystem(
      builders: {
        'summary_card': buildSummaryCard,
        'chart': buildChart,
        'task_item': buildTaskItem,
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexus Dashboard Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Project Dashboard'),
          elevation: 0,
        ),
        body: NexusWidget(
          worldProvider: provideDashboardWorld,
          renderingSystem: renderingSystem,
        ),
      ),
    );
  }
}
