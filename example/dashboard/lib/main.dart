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
  world.addSystem(RealtimeDataSystem());

  // --- NEW: Add a system that animates the root container's border ---
  world.addSystem(RootBorderAnimationSystem());
  // --- END NEW ---

  world.loadModule(DashboardModule());
  return world;
}

// --- NEW: A system to animate the border color of the root entity ---
class RootBorderAnimationSystem extends System {
  @override
  bool matches(Entity entity) {
    return entity.get<TagsComponent>()?.hasTag('root') ?? false;
  }

  @override
  void update(Entity entity, double dt) {
    // This is a simple animation, we'll just add an AnimationComponent
    // if it doesn't already exist.
    if (!entity.has<AnimationComponent>()) {
      entity.add(AnimationComponent(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        repeat: true,
        onUpdate: (e, value) {
          // We'll store the color value in a custom component.
          // The value will ping-pong between 0.0 and 1.0.
          final progress = (value < 0.5) ? value * 2 : (1.0 - value) * 2;
          e.add(BorderAnimationProgress(progress));
        },
      ));
    }
  }
}

// --- NEW: A component to hold the border animation progress ---
class BorderAnimationProgress extends Component with SerializableComponent {
  final double progress;
  BorderAnimationProgress(this.progress);

  factory BorderAnimationProgress.fromJson(Map<String, dynamic> json) =>
      BorderAnimationProgress(json['progress']);

  @override
  Map<String, dynamic> toJson() => {'progress': progress};

  @override
  List<Object?> get props => [progress];
}
// --- END NEW ---

/// A helper function to register all serializable components.
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
  ComponentFactoryRegistry.I.register('RealtimeChartComponent',
      (json) => RealtimeChartComponent.fromJson(json));
  // NEW: Register our new components
  ComponentFactoryRegistry.I.register('RenderStrategyComponent',
      (json) => RenderStrategyComponent.fromJson(json));
  ComponentFactoryRegistry.I.register('BorderAnimationProgress',
      (json) => BorderAnimationProgress.fromJson(json));
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
        'realtime_chart': buildRealtimeChart,
        // --- NEW: A custom builder for our root container ---
        'root_container': (context, id, controller, manager) {
          final progress =
              controller.get<BorderAnimationProgress>(id)?.progress ?? 0.0;
          final color =
              Color.lerp(Colors.grey.shade300, Colors.deepPurple, progress)!;

          // This is a conceptual example. In the modified rendering system,
          // the children are built and cached automatically. This builder
          // is only responsible for the "shell".
          return Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
            // The children will be placed inside this container by the rendering system.
            // For this example, we assume the builder doesn't need to manage children directly.
            // A more robust implementation would pass a `child` widget to this builder.
            child:
                const SizedBox(), // Placeholder, children are handled by the system
          );
        },
        // --- END NEW ---
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
