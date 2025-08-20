import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

/// Assembles all entities related to the counter feature.
/// This assembler now only creates isolate-safe data components.
class CounterEntityAssembler extends EntityAssembler<CounterCubit> {
  CounterEntityAssembler(NexusWorld world, CounterCubit cubit)
      : super(world, cubit);

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
    entity.add(PositionComponent(x: 80, y: 250, width: 250, height: 100));
    entity.add(BlocComponent<CounterCubit, int>(cubit));
    entity.add(CounterStateComponent(cubit.state));
    entity.add(TagsComponent({BuilderTags.counterDisplay}));
    entity.add(MorphingLogicComponent(initialSides: 4, targetSides: 4));
    return entity;
  }

  /// Creates the shape-shifting buttons.
  List<Entity> _createShapeButtons() {
    final List<Entity> buttons = [];
    final positions = [
      const [20.0, 450.0],
      const [90.0, 450.0],
      const [160.0, 450.0],
      const [230.0, 450.0],
      const [300.0, 450.0],
    ];
    final sides = [3, 4, 5, 6, 30];

    for (var i = 0; i < sides.length; i++) {
      final entity = Entity();
      entity.add(PositionComponent(
          x: positions[i][0], y: positions[i][1], width: 60, height: 60));
      entity.add(ShapePathComponent(sides: sides[i]));
      entity.add(ClickableComponent((e) {
        world.eventBus.fire(ShapeSelectedEvent(sides[i]));
      }));
      // Use the generic custom widget tag
      entity.add(TagsComponent({BuilderTags.customWidget}));
      // Provide the data blueprint for the widget
      entity.add(CustomWidgetComponent(
        widgetType: 'shape_button',
      ));
      buttons.add(entity);
    }
    return buttons;
  }

  /// Creates the increment button entity.
  Entity _createIncrementButton() {
    final entity = Entity();
    entity.add(PositionComponent(x: 220, y: 370, width: 110, height: 50));
    entity.add(ClickableComponent((_) => cubit.increment()));
    entity.add(TagsComponent({BuilderTags.customWidget}));
    entity.add(CustomWidgetComponent(
      widgetType: 'elevated_button',
      properties: {'icon': 0xe047}, // Icons.add code point
    ));
    return entity;
  }

  /// Creates the decrement button entity.
  Entity _createDecrementButton() {
    final entity = Entity();
    entity.add(PositionComponent(x: 80, y: 370, width: 110, height: 50));
    entity.add(ClickableComponent((_) => cubit.decrement()));
    entity.add(TagsComponent({BuilderTags.customWidget}));
    entity.add(CustomWidgetComponent(
      widgetType: 'elevated_button',
      properties: {'icon': 0xe516}, // Icons.remove code point
    ));
    return entity;
  }
}
