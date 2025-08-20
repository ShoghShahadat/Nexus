import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';
import 'package:nexus_example/dashboard_module/data/mock_data_provider.dart';

/// Provides all entities related to the dashboard feature.
/// It uses the official EntityAssembler pattern for clean separation of concerns.
class DashboardEntityProvider extends EntityProvider {
  @override
  void createEntities(NexusWorld world) {
    // Instantiate the assembler.
    final assembler = DashboardEntityAssembler(world);

    // Use the assembler to create and add all its entities to the world.
    for (final entity in assembler.assemble()) {
      world.addEntity(entity);
    }
  }
}

/// Assembles all entities related to the dashboard feature.
/// This class contains the concrete logic for creating and configuring entities.
class DashboardEntityAssembler extends EntityAssembler<void> {
  DashboardEntityAssembler(NexusWorld world) : super(world, null);

  // A helper to get the data provider service.
  MockDataProvider get dataProvider => world.services.get<MockDataProvider>();

  @override
  List<Entity> assemble() {
    return [
      ..._createSummaryCards(),
      _createChart(),
      ..._createTaskList(),
    ];
  }

  /// Creates entities for the summary cards at the top of the dashboard.
  List<Entity> _createSummaryCards() {
    final cards = dataProvider.getSummaryCards();
    final List<Entity> entities = [];
    double startX = 20.0;
    double cardWidth = 200.0;
    double spacing = 20.0;

    for (int i = 0; i < cards.length; i++) {
      final cardData = cards[i];
      final entity = Entity();

      entity.add(PositionComponent(
          x: startX + (cardWidth + spacing) * i,
          y: 20.0,
          width: cardWidth,
          height: 100.0));
      entity.add(cardData); // Add the specific card data component
      entity
          .add(EntryAnimationComponent(delay: 0.1 * i)); // Staggered animation
      entity.add(TagsComponent({'summary_card'})); // UI builder tag

      entities.add(entity);
    }
    return entities;
  }

  /// Creates the entity for the bar chart.
  Entity _createChart() {
    final entity = Entity();
    entity.add(PositionComponent(x: 20, y: 140, width: 420, height: 250));
    entity.add(dataProvider.getChartData()); // Add chart data
    entity.add(EntryAnimationComponent(delay: 0.4));
    entity.add(TagsComponent({'chart'})); // UI builder tag
    return entity;
  }

  /// Creates entities for the task list items.
  List<Entity> _createTaskList() {
    final tasks = dataProvider.getTasks();
    final List<Entity> entities = [];
    double startY = 410.0;
    double itemHeight = 60.0;
    double spacing = 10.0;

    for (int i = 0; i < tasks.length; i++) {
      final taskData = tasks[i];
      final entity = Entity();

      entity.add(PositionComponent(
          x: 20,
          y: startY + (itemHeight + spacing) * i,
          width: 840, // Wider to fit content
          height: itemHeight));
      entity.add(taskData); // Add the specific task data component
      entity.add(EntryAnimationComponent(delay: 0.5 + (0.05 * i))); // Staggered
      entity.add(TagsComponent({'task_item'})); // UI builder tag

      entities.add(entity);
    }
    return entities;
  }
}
