import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';
import 'package:nexus_example/dashboard_module/data/mock_data_provider.dart';

/// Provides all entities for the dashboard, now structured hierarchically.
class DashboardEntityProvider extends EntityProvider {
  @override
  void createEntities(NexusWorld world) {
    final assembler = DashboardEntityAssembler(world);
    for (final entity in assembler.assemble()) {
      world.addEntity(entity);
    }
  }
}

/// Assembles a hierarchical structure of entities for a Flutter-like layout.
class DashboardEntityAssembler extends EntityAssembler<void> {
  DashboardEntityAssembler(NexusWorld world) : super(world, null);

  MockDataProvider get dataProvider => world.services.get<MockDataProvider>();

  @override
  List<Entity> assemble() {
    // Create individual widget entities first.
    final summaryCards = _createSummaryCards();
    final chart = _createChart();
    final taskList = _createTaskList();

    // Create layout container entities.
    final summaryGrid = _createLayoutEntity(
      widgetType: 'wrap', // Use a Wrap for responsive grid
      children: summaryCards.map((e) => e.id).toList(),
    );

    final taskColumn = _createLayoutEntity(
      widgetType: 'column',
      children: taskList.map((e) => e.id).toList(),
    );

    // Create the main root entity that will be the main Column.
    final rootEntity = _createLayoutEntity(
      widgetType: 'column',
      tag: 'root', // A special tag to identify the entry point for rendering.
      children: [
        summaryGrid.id,
        chart.id,
        taskColumn.id,
      ],
    );

    // Return all created entities to be added to the world.
    return [
      rootEntity,
      summaryGrid,
      chart,
      taskColumn,
      ...summaryCards,
      ...taskList,
    ];
  }

  /// Helper to create a layout container entity.
  Entity _createLayoutEntity(
      {required String widgetType,
      required List<EntityId> children,
      String? tag}) {
    final entity = Entity();
    entity.add(CustomWidgetComponent(widgetType: widgetType));
    entity.add(ChildrenComponent(children));
    if (tag != null) {
      entity.add(TagsComponent({tag}));
    }
    return entity;
  }

  /// Creates entities for the summary cards. They no longer have positions.
  List<Entity> _createSummaryCards() {
    final cards = dataProvider.getSummaryCards();
    return List.generate(cards.length, (i) {
      final cardData = cards[i];
      final entity = Entity();
      // No PositionComponent needed here anymore!
      entity.add(CustomWidgetComponent(
        widgetType: 'summary_card',
        properties: {'width': 200.0, 'height': 120.0},
      ));
      entity.add(cardData);
      entity.add(EntryAnimationComponent(delay: 0.1 * i));
      return entity;
    });
  }

  /// Creates the entity for the bar chart.
  Entity _createChart() {
    final entity = Entity();
    entity.add(CustomWidgetComponent(
      widgetType: 'chart',
      properties: {'height': 250.0},
    ));
    entity.add(dataProvider.getChartData());
    entity.add(EntryAnimationComponent(delay: 0.4));
    return entity;
  }

  /// Creates entities for the task list items.
  List<Entity> _createTaskList() {
    final tasks = dataProvider.getTasks();
    return List.generate(tasks.length, (i) {
      final taskData = tasks[i];
      final entity = Entity();
      entity.add(CustomWidgetComponent(widgetType: 'task_item'));
      entity.add(taskData);
      entity.add(EntryAnimationComponent(delay: 0.5 + (0.05 * i)));
      entity.add(ClickableComponent((e) {
        final currentTask = e.get<TaskItemComponent>()!;
        e.add(TaskItemComponent(
          title: currentTask.title,
          assignedTo: currentTask.assignedTo,
          priority: currentTask.priority,
          isCompleted: !currentTask.isCompleted,
        ));
      }));
      return entity;
    });
  }
}
