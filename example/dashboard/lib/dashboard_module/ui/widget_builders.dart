import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';
import 'package:nexus_example/dashboard_module/ui/custom_painters.dart';

/// This file contains the widget building logic for the dashboard entities.
/// Each function is a `TaggedWidgetBuilder` responsible for rendering a specific
/// type of entity based on its components.

/// Builds the widget for a summary card entity.
Widget buildSummaryCard(BuildContext context, EntityId id,
    FlutterRenderingSystem controller, NexusIsolateManager manager) {
  final cardData = controller.get<SummaryCardComponent>(id);
  if (cardData == null) return const SizedBox.shrink();

  return Card(
    elevation: 4.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cardData.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black54),
              ),
              Icon(
                IconData(cardData.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Color(cardData.colorValue),
              ),
            ],
          ),
          Text(
            cardData.value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds the widget for the bar chart entity.
Widget buildChart(BuildContext context, EntityId id,
    FlutterRenderingSystem controller, NexusIsolateManager manager) {
  final chartData = controller.get<ChartDataComponent>(id);
  // The animation progress is driven by the scale of the PositionComponent,
  // which is updated by the EntryAnimationSystem.
  final pos = controller.get<PositionComponent>(id);
  if (chartData == null || pos == null) return const SizedBox.shrink();

  return Card(
    elevation: 4.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chartData.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: BarChartPainter(
                values: chartData.weeklyData,
                animationProgress: pos.scale, // Use scale as animation progress
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds the widget for a task list item entity.
Widget buildTaskItem(BuildContext context, EntityId id,
    FlutterRenderingSystem controller, NexusIsolateManager manager) {
  final taskData = controller.get<TaskItemComponent>(id);
  if (taskData == null) return const SizedBox.shrink();

  final priorityColor = taskData.priority == 'High'
      ? Colors.red.shade300
      : taskData.priority == 'Medium'
          ? Colors.orange.shade300
          : Colors.grey.shade400;

  return Card(
    elevation: 2.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: ListTile(
      leading: Icon(
        taskData.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
        color: taskData.isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(
        taskData.title,
        style: TextStyle(
          decoration: taskData.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text('Assigned to: ${taskData.assignedTo}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: priorityColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          taskData.priority,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ),
  );
}
