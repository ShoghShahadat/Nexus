import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/counter_module.dart';
import 'package:nexus_example/counter_module/ui/button_painters.dart';
import 'package:nexus_example/counter_module/ui/morphing_painter.dart';
import 'package:nexus_example/counter_module/utils/shape_utils.dart';

// --- World Provider ---
// This function will be executed in the background isolate.
NexusWorld provideNexusWorld() {
  final world = NexusWorld();
  world.services.registerSingleton(CounterCubit());
  world.addSystem(AnimationSystem());
  world.addSystem(PulsingWarningSystem());
  world.addSystem(MorphingSystem());
  world.addSystem(LifecycleSystem());
  world.addSystem(InputSystem());
  world.loadModule(CounterModule());
  return world;
}

void main() {
  registerCoreComponents();
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final renderingSystem = FlutterRenderingSystem(
      builders: {
        BuilderTags.counterDisplay: (context, id, controller, manager) {
          final stateComp = controller.get<CounterStateComponent>(id);
          final morph = controller.get<MorphingLogicComponent>(id);
          final pos = controller.get<PositionComponent>(id);
          final anim = controller.get<AnimationProgressComponent>(id);

          if (stateComp == null || morph == null || pos == null) {
            return const SizedBox.shrink();
          }

          final state = stateComp.value;
          final color = state >= 0 ? Colors.deepPurple : Colors.redAccent;

          final startPath = getPolygonPath(
              Size(pos.width, pos.height), morph.initialSides,
              cornerRadius: 12.0);
          final endPath = getPolygonPath(
              Size(pos.width, pos.height), morph.targetSides,
              cornerRadius: 12.0);

          final progress = anim?.progress ?? 1.0;

          return CustomPaint(
            painter: MorphingPainter(
              startPath: startPath,
              endPath: endPath,
              progress: progress,
              color: color,
              text: 'Count: $state',
            ),
          );
        },
        // The single, smart builder that acts as a widget factory.
        BuilderTags.customWidget: (context, id, controller, manager) {
          final widgetComp = controller.get<CustomWidgetComponent>(id);
          if (widgetComp == null) return const SizedBox.shrink();

          // Read the blueprint and build the corresponding widget.
          switch (widgetComp.widgetType) {
            case 'elevated_button':
              final iconCode = widgetComp.properties['icon'] as int?;
              return ElevatedButton(
                onPressed: () => manager.send(EntityTapEvent(id)),
                child: Icon(iconCode != null
                    ? IconData(iconCode, fontFamily: 'MaterialIcons')
                    : null),
              );
            case 'shape_button':
              final shape = controller.get<ShapePathComponent>(id);
              final pos = controller.get<PositionComponent>(id);
              if (shape == null || pos == null) return const SizedBox.shrink();
              final path =
                  getPolygonPath(Size(pos.width, pos.height), shape.sides);
              return GestureDetector(
                onTap: () => manager.send(EntityTapEvent(id)),
                child: Container(
                  color: Colors.transparent,
                  child: CustomPaint(
                      size: Size(pos.width, pos.height),
                      painter: ShapeButtonPainter(path: path)),
                ),
              );
            default:
              return Text('Unknown widget type: ${widgetComp.widgetType}');
          }
        },
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text('Nexus Isolate Example',
              style: TextStyle(color: Colors.white)),
        ),
        body: NexusWidget(
          worldProvider: provideNexusWorld,
          renderingSystem: renderingSystem,
        ),
      ),
    );
  }
}
