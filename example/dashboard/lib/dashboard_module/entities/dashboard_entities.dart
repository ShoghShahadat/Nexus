import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';
import 'package:nexus_example/dashboard_module/data/mock_data_provider.dart';

/// Provides all entities related to the dashboard feature.
class DashboardEntityProvider extends EntityProvider {
  @override
  void createEntities(NexusWorld world) {
    final assembler = DashboardEntityAssembler(world);
    for (final entity in assembler.assemble()) {
      world.addEntity(entity);
    }
  }
}

/// Assembles all entities related to the dashboard feature.
class DashboardEntityAssembler extends EntityAssembler<void> {
  DashboardEntityAssembler(NexusWorld world) : super(world, null);

  MockDataProvider get dataProvider => world.services.get<MockDataProvider>();

  @override
  List<Entity> assemble() {
    return [
      ..._createSummaryCards(),
      _createChart(),
      ..._createTaskList(),
    ];
  }

  /// Creates entities for the summary cards with a new 2x2 grid layout.
  List<Entity> _createSummaryCards() {
    final cards = dataProvider.getSummaryCards();
    final List<Entity> entities = [];
    double cardWidth = 200.0;
    double cardHeight = 120.0;
    double spacing = 20.0;
    double startX = 20.0;
    double startY = 20.0;

    for (int i = 0; i < cards.length; i++) {
      final cardData = cards[i];
      final entity = Entity();

      // 2x2 Grid calculation
      final row = i ~/ 2;
      final col = i % 2;

      entity.add(PositionComponent(
          x: startX + col * (cardWidth + spacing),
          y: startY + row * (cardHeight + spacing),
          width: cardWidth,
          height: cardHeight));
      entity.add(cardData);
      entity.add(EntryAnimationComponent(delay: 0.1 * i));
      entity.add(TagsComponent({'summary_card'}));

      entities.add(entity);
    }
    return entities;
  }

  /// Creates the entity for the bar chart, positioned below the cards.
  Entity _createChart() {
    final entity = Entity();
    entity.add(PositionComponent(x: 20, y: 300, width: 420, height: 250));
    entity.add(dataProvider.getChartData());
    entity.add(EntryAnimationComponent(delay: 0.4));
    entity.add(TagsComponent({'chart'}));
    return entity;
  }

  /// Creates entities for the task list items.
  List<Entity> _createTaskList() {
    final tasks = dataProvider.getTasks();
    final List<Entity> entities = [];
    double startY = 570.0;
    double itemHeight = 65.0;
    double spacing = 15.0;

    for (int i = 0; i < tasks.length; i++) {
      final taskData = tasks[i];
      final entity = Entity();

      entity.add(PositionComponent(
          x: 20,
          y: startY + (itemHeight + spacing) * i,
          width: 420, // Adjusted width
          height: itemHeight));
      entity.add(taskData);
      entity.add(EntryAnimationComponent(delay: 0.5 + (0.05 * i)));
      entity.add(TagsComponent({'task_item'}));

      // *** FIX: Add ClickableComponent for interactivity ***
      // This component's onTap callback runs in the background isolate.
      entity.add(ClickableComponent((e) {
        final currentTask = e.get<TaskItemComponent>();
        if (currentTask == null) return;

        // Create a new component with the toggled state.
        final updatedTask = TaskItemComponent(
          title: currentTask.title,
          assignedTo: currentTask.assignedTo,
          priority: currentTask.priority,
          isCompleted: !currentTask.isCompleted, // Toggle the value
        );
        // Re-add the component to the entity to trigger an update.
        e.add(updatedTask);
      }));

      entities.add(entity);
    }
    return entities;
  }
}
