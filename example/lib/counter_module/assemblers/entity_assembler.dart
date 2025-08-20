import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/utils/shape_utils.dart';
import 'dart:ui'; // For Size

/// Assembles all entities related to the counter feature.
///
/// This class now extends the official [EntityAssembler] from the Nexus
/// framework, providing a standardized structure for entity creation.
/// NOTE: This assembler now contains NO FLUTTER-SPECIFIC CODE. It only
/// deals with pure data components.
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
    entity.add(TagsComponent({'counter_display'})); // Tag for the UI
    entity.add(
        MorphingComponent(initialPath: initialPath, targetPath: initialPath));
    // WidgetComponent is removed. The UI is now handled by FlutterRenderingSystem
    // based on the 'counter_display' tag.
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
      entity.add(TagsComponent({'shape_button'})); // Tag for the UI
      buttons.add(entity);
    }
    return buttons;
  }

  /// Creates the increment button entity.
  Entity _createIncrementButton() {
    final entity = Entity();
    entity.add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
    entity.add(ClickableComponent((_) => cubit.increment()));
    entity.add(TagsComponent({'increment_button'})); // Tag for the UI
    return entity;
  }

  /// Creates the decrement button entity.
  Entity _createDecrementButton() {
    final entity = Entity();
    entity.add(PositionComponent(x: 80, y: 370, width: 110, height: 50));
    entity.add(ClickableComponent((_) => cubit.decrement()));
    entity.add(TagsComponent({'decrement_button'})); // Tag for the UI
    return entity;
  }
}
