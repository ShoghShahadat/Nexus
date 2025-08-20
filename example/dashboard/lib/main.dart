import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';
import 'package:nexus_example/dashboard_module/dashboard_module.dart';
import 'package:nexus_example/dashboard_module/systems/dashboard_systems.dart';
import 'package:nexus_example/dashboard_module/ui/widget_builders.dart';

/// The entry point for the background isolate.
NexusWorld provideDashboardWorld() {
  final world = NexusWorld();
  world.addSystem(AnimationSystem());
  world.addSystem(LifecycleSystem());
  world.addSystem(InputSystem());
  world.addSystem(TaskExpansionSystem());
  // *** NEW: Add the RealtimeDataSystem to the world. ***
  world.addSystem(RealtimeDataSystem());
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
  ComponentFactoryRegistry.I.register('ExpandedStateComponent',
      (json) => ExpandedStateComponent.fromJson(json));
  // *** NEW: Register the new RealtimeChartComponent. ***
  ComponentFactoryRegistry.I.register('RealtimeChartComponent',
      (json) => RealtimeChartComponent.fromJson(json));
}

/// The main entry point for the Flutter application.
void main() {
  registerCoreComponents();
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
        // *** NEW: Add the builder for the real-time chart. ***
        'realtime_chart': buildRealtimeChart,
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
