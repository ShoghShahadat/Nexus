import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/ui/button_painters.dart';
import 'package:nexus_example/counter_module/ui/morphing_painter.dart';
import 'package:nexus_example/counter_module/utils/shape_utils.dart';

/// Assembles all entities related to the counter feature.
///
/// This class now extends the official [EntityAssembler] from the Nexus
/// framework, providing a standardized structure for entity creation.
class CounterEntityAssembler extends EntityAssembler<CounterCubit> {
  CounterEntityAssembler(NexusWorld world, CounterCubit cubit)
      : super(world, cubit);

  // The cubit is now accessible via the 'context' property from the base class.
  CounterCubit get cubit => context;

  @override
  List<Entity> assemble() {
    return [
      _createCounterDisplay(),
      _createIncrementButton(),
      _createDecrementButton(),
      ..._createShapeButtons(),
    ];
  }

  /// Creates the main counter display entity.
  Entity _createCounterDisplay() {
    final entity = Entity();
    final size = const Size(250, 100);
    final initialPath = getPolygonPath(size, 4, cornerRadius: 12);

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
        painter: MorphingPainter(
            path: morph.currentPath, color: color, text: 'Count: $state'),
      );
    }));
    return entity;
  }

  /// Creates the shape-shifting buttons.
  List<Entity> _createShapeButtons() {
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
      final shapePath = getPolygonPath(buttonSize, sides[i]);

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
        return GestureDetector(
          onTap: () => entity.get<ClickableComponent>()!.onTap(entity),
          child: Container(
            color: Colors.transparent,
            child: CustomPaint(
                size: buttonSize, painter: ShapeButtonPainter(path: shapePath)),
          ),
        );
      }));
      buttons.add(entity);
    }
    return buttons;
  }

  /// Creates the increment button entity.
  Entity _createIncrementButton() {
    final entity = Entity();
    entity.add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
    entity.add(ClickableComponent((_) => cubit.increment()));
    entity.add(WidgetComponent((context, entity) {
      return ElevatedButton(
        onPressed: () => entity.get<ClickableComponent>()!.onTap(entity),
        child: const Icon(Icons.add),
      );
    }));
    return entity;
  }

  /// Creates the decrement button entity.
  Entity _createDecrementButton() {
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
