import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

/// A self-contained module for the counter feature.
class CounterModule extends NexusModule {
  @override
  List<System> get systems => [_CounterDisplaySystem(), ShapeSelectionSystem()];

  void createEntities(NexusWorld world, CounterCubit counterCubit) {
    world.addEntity(_createCounterDisplay(counterCubit));
    world.addEntity(_createIncrementButton(world, counterCubit));
    world.addEntity(_createDecrementButton(world, counterCubit));

    final shapeButtons = _createShapeButtons(world);
    for (final button in shapeButtons) {
      world.addEntity(button);
    }
  }

  Entity _createCounterDisplay(CounterCubit cubit) {
    final entity = Entity();
    final size = const Size(250, 100);
    final initialPath = _getPolygonPath(size, 4, cornerRadius: 12);

    entity.add(PositionComponent(
        x: 80, y: 250, width: size.width, height: size.height));
    entity.add(BlocComponent<CounterCubit, int>(cubit));
    entity.add(CounterStateComponent(cubit.state));
    entity.add(TagsComponent({'counter_display'}));
    entity.add(
        MorphingComponent(initialPath: initialPath, targetPath: initialPath));
    entity.add(WidgetComponent((context, entity) {
      final state = entity.get<CounterStateComponent>()!.value;
      final morph = entity.get<MorphingComponent>()!;
      final color = state >= 0 ? Colors.deepPurple : Colors.redAccent;

      return CustomPaint(
        painter: _MorphingPainter(
          path: morph.currentPath,
          color: color,
          text: 'Count: $state',
        ),
      );
    }));
    return entity;
  }

  List<Entity> _createShapeButtons(NexusWorld world) {
    final List<Entity> buttons = [];
    const buttonSize = Size(60, 60);
    final positions = [
      const Offset(20, 450),
      const Offset(90, 450),
      const Offset(160, 450),
      const Offset(230, 450),
      const Offset(300, 450),
    ];
    final sides = [3, 4, 5, 6, 30];

    for (var i = 0; i < sides.length; i++) {
      final entity = Entity();
      final shapePath = _getPolygonPath(buttonSize, sides[i]);

      entity.add(PositionComponent(
          x: positions[i].dx,
          y: positions[i].dy,
          width: buttonSize.width,
          height: buttonSize.height));
      entity.add(ShapePathComponent(shapePath));
      entity.add(ClickableComponent((e) {
        final path = e.get<ShapePathComponent>()!.path;
        world.eventBus.fire(ShapeSelectedEvent(path));
      }));
      entity.add(WidgetComponent((context, entity) {
        // THE DEFINITIVE FIX: Use a standard GestureDetector inside the builder.
        // This is the idiomatic Flutter way and guarantees correct hit detection.
        return GestureDetector(
          onTap: () => entity.get<ClickableComponent>()!.onTap(entity),
          child: Container(
            color:
                Colors.transparent, // Ensures the GestureDetector is hittable
            child: CustomPaint(
              size: buttonSize,
              painter: _ShapeButtonPainter(path: shapePath),
            ),
          ),
        );
      }));
      buttons.add(entity);
    }
    return buttons;
  }

  Entity _createIncrementButton(NexusWorld world, CounterCubit cubit) {
    final entity = Entity();
    entity.add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
    entity.add(ClickableComponent((_) => cubit.increment()));
    entity.add(WidgetComponent((context, entity) {
      // DEMONSTRATION OF FLEXIBILITY:
      // We can use any Flutter widget, including ElevatedButton.
      return ElevatedButton(
        onPressed: () => entity.get<ClickableComponent>()!.onTap(entity),
        child: const Icon(Icons.add),
      );
    }));
    return entity;
  }

  Entity _createDecrementButton(NexusWorld world, CounterCubit cubit) {
    final entity = Entity();
    entity.add(PositionComponent(x: 80, y: 370, width: 110, height: 50));
    entity.add(ClickableComponent((_) => cubit.decrement()));
    entity.add(WidgetComponent((context, entity) {
      return ElevatedButton(
        onPressed: () => entity.get<ClickableComponent>()!.onTap(entity),
        child: const Icon(Icons.remove),
      );
    }));
    return entity;
  }
}

class _CounterDisplaySystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(Entity entity, int state) {
    entity.add(CounterStateComponent(state));
    final tags = entity.get<TagsComponent>()!;
    final isWarning = state < 0;
    final wasWarning = tags.hasTag('warning');
    if (isWarning && !wasWarning) {
      tags.add('warning');
      entity.add(tags);
    } else if (!isWarning && wasWarning) {
      tags.remove('warning');
      entity.add(tags);
    }
  }
}

// --- Helper function to define shapes ---
Path _getPolygonPath(Size size, int sides, {double cornerRadius = 0.0}) {
  final path = Path();
  final radius = min(size.width, size.height) / 2;
  final centerX = size.width / 2;
  final centerY = size.height / 2;
  final angle = (pi * 2) / sides;

  if (sides > 20) {
    return path
      ..addOval(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));
  }
  if (sides == 4 && cornerRadius > 0) {
    return path
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(cornerRadius)));
  }

  final points = <Offset>[];
  for (int i = 0; i < sides; i++) {
    final x = centerX + cos(i * angle - pi / 2) * radius;
    final y = centerY + sin(i * angle - pi / 2) * radius;
    points.add(Offset(x, y));
  }
  path.moveTo(points.last.dx, points.last.dy);
  for (final point in points) {
    path.lineTo(point.dx, point.dy);
  }
  path.close();
  return path;
}

// --- Custom Painters ---
class _MorphingPainter extends CustomPainter {
  final Path path;
  final Color color;
  final String text;

  _MorphingPainter(
      {required this.path, required this.color, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final bounds = path.getBounds();
    if (bounds.width == 0 || bounds.height == 0) return;

    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final transform = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scaleX, scaleY)
      ..translate(-bounds.center.dx, -bounds.center.dy);
    final scaledPath = path.transform(transform.storage);

    canvas.drawShadow(scaledPath, Colors.black.withOpacity(0.5), 4.0, true);
    canvas.drawPath(scaledPath, paint);

    final textSpan = TextSpan(
        text: text,
        style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold));
    final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: size.width);
    final offset = Offset((size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MorphingPainter oldDelegate) => true;
}

class _ShapeButtonPainter extends CustomPainter {
  final Path path;
  _ShapeButtonPainter({required this.path});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final bounds = path.getBounds();
    if (bounds.width == 0 || bounds.height == 0) return;

    final scale =
        min(size.width / bounds.width, size.height / bounds.height) * 0.8;
    final transform = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale, scale)
      ..translate(-bounds.center.dx, -bounds.center.dy);
    final scaledPath = path.transform(transform.storage);

    canvas.drawPath(scaledPath, paint);
    canvas.drawPath(scaledPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
