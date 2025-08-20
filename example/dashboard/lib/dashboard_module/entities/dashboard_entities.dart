import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';
import 'package:nexus_example/dashboard_module/data/mock_data_provider.dart';

/// Provides all entities for the dashboard, structured hierarchically.
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
    final summaryCards = _createSummaryCards();
    final chart = _createChart();
    final realtimeChart = _createRealtimeChart();
    final taskList = _createTaskList();

    final summaryGrid = _createLayoutEntity(
      widgetType: 'wrap',
      children: summaryCards.map((e) => e.id).toList(),
    );

    final taskColumn = _createLayoutEntity(
      widgetType: 'column',
      children: taskList.map((e) => e.id).toList(),
    );

    // --- MODIFIED: The root entity is now a container with a static shell ---
    final rootEntity = Entity();
    rootEntity.add(CustomWidgetComponent(widgetType: 'root_container'));
    rootEntity.add(TagsComponent({'root'}));
    rootEntity.add(ChildrenComponent([
      summaryGrid.id,
      chart.id,
      realtimeChart.id,
      taskColumn.id,
    ]));
    // This is the key instruction: only rebuild the shell, not the children.
    rootEntity.add(RenderStrategyComponent(RenderBehavior.staticShell));
    // --- END MODIFICATION ---

    return [
      rootEntity,
      summaryGrid,
      chart,
      realtimeChart,
      taskColumn,
      ...summaryCards,
      ...taskList,
    ];
  }

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

  List<Entity> _createSummaryCards() {
    final cards = dataProvider.getSummaryCards();
    return List.generate(cards.length, (i) {
      final cardData = cards[i];
      final entity = Entity();
      entity.add(CustomWidgetComponent(
        widgetType: 'summary_card',
        properties: {'width': 220.0, 'height': 120.0},
      ));
      entity.add(cardData);
      entity.add(EntryAnimationComponent(delay: 0.1 * i));
      return entity;
    });
  }

  Entity _createChart() {
    final entity = Entity();
    entity.add(CustomWidgetComponent(
      widgetType: 'chart',
      properties: {'height': 280.0},
    ));
    entity.add(dataProvider.getChartData());
    entity.add(EntryAnimationComponent(delay: 0.4));
    return entity;
  }

  Entity _createRealtimeChart() {
    final entity = Entity();
    entity.add(CustomWidgetComponent(
      widgetType: 'realtime_chart',
      properties: {'height': 150.0},
    ));
    entity.add(RealtimeChartComponent([]));
    entity.add(EntryAnimationComponent(delay: 0.6));
    return entity;
  }

  List<Entity> _createTaskList() {
    final tasks = dataProvider.getTasks();
    return List.generate(tasks.length, (i) {
      final taskData = tasks[i];
      final entity = Entity();
      entity.add(CustomWidgetComponent(widgetType: 'task_item'));
      entity.add(taskData);
      entity.add(EntryAnimationComponent(delay: 0.7 + (0.05 * i)));

      if (taskData.isCompleted) {
        entity.add(ExpandedStateComponent(progress: 1.0, isExpanding: true));
      }

      entity.add(ClickableComponent((e) {
        if (e.has<AnimationComponent>()) return;

        final currentTask = e.get<TaskItemComponent>()!;
        final expansionState = e.get<ExpandedStateComponent>();

        e.add(TaskItemComponent(
          title: currentTask.title,
          assignedTo: currentTask.assignedTo,
          priority: currentTask.priority,
          isCompleted: !currentTask.isCompleted,
          description: currentTask.description,
          createdDate: currentTask.createdDate,
        ));

        if (expansionState == null) {
          e.add(ExpandedStateComponent(isExpanding: true));
        } else {
          e.add(ExpandedStateComponent(
            progress: expansionState.progress,
            isExpanding: false,
          ));
        }
      }));
      return entity;
    });
  }
}
