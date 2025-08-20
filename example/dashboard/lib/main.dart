import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';
import 'package:nexus_example/dashboard_module/dashboard_module.dart';
import 'package:nexus_example/dashboard_module/ui/widget_builders.dart';

/// The entry point for the background isolate.
NexusWorld provideDashboardWorld() {
  final world = NexusWorld();
  world.addSystem(AnimationSystem());
  world.addSystem(LifecycleSystem());
  world.addSystem(InputSystem());
  world.loadModule(DashboardModule());
  return world;
}

/// A helper function to register all serializable components from the dashboard module.
void registerDashboardComponents() {
  ComponentFactoryRegistry.I.register(
      'SummaryCardComponent', (json) => SummaryCardComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'ChartDataComponent', (json) => ChartDataComponent.fromJson(json));
  ComponentFactoryRegistry.I.register(
      'TaskItemComponent', (json) => TaskItemComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('EntryAnimationComponent',
      (json) => EntryAnimationComponent.fromJson(json));
  // *** FIX: No longer need to register ChildrenComponent here. ***
  // It's now part of the core library.
}

/// The main entry point for the Flutter application.
void main() {
  // This registers all components from the library.
  registerCoreComponents();
  // This registers components specific to this application.
  registerDashboardComponents();
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        fontFamily: 'Inter',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Project Dashboard'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        // The body is now a fully standard, scrollable Flutter layout
        // driven by Nexus in the background.
        body: SingleChildScrollView(
          child: NexusWidget(
            worldProvider: provideDashboardWorld,
            renderingSystem: renderingSystem,
            isolateInitializer: registerDashboardComponents,
          ),
        ),
      ),
    );
  }
}
