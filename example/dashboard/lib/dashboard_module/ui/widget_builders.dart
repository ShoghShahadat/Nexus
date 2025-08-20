import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';
import 'package:nexus_example/dashboard_module/ui/custom_painters.dart';

/// This file contains the widget building logic for the dashboard entities.
/// These builders are now designed to work within a standard Flutter layout (like Column or Wrap).

/// Builds the widget for a summary card entity.
Widget buildSummaryCard(BuildContext context, EntityId id,
    FlutterRenderingSystem controller, NexusIsolateManager manager) {
  final cardData = controller.get<SummaryCardComponent>(id);
  final widgetData = controller.get<CustomWidgetComponent>(id);
  if (cardData == null || widgetData == null) return const SizedBox.shrink();

  // The size is now provided via properties, making the component more reusable.
  final width = widgetData.properties['width'] as double? ?? 200.0;
  final height = widgetData.properties['height'] as double? ?? 120.0;

  return SizedBox(
    width: width,
    height: height,
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(cardData.colorValue).withOpacity(0.7),
            Color(cardData.colorValue)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Placeholder
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cardData.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      IconData(cardData.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cardData.title,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Builds the widget for the bar chart entity.
Widget buildChart(BuildContext context, EntityId id,
    FlutterRenderingSystem controller, NexusIsolateManager manager) {
  final chartData = controller.get<ChartDataComponent>(id);
  final widgetData = controller.get<CustomWidgetComponent>(id);
  // Animation is now driven by a separate component, not PositionComponent.
  final animProgress = controller.get<AnimationProgressComponent>(id);
  if (chartData == null || widgetData == null) return const SizedBox.shrink();

  final height = widgetData.properties['height'] as double? ?? 250.0;

  return SizedBox(
    height: height,
    child: Card(
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartData.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: CustomPaint(
                painter: BarChartPainter(
                  values: chartData.weeklyData,
                  animationProgress: animProgress?.progress ??
                      1.0, // Use progress from the component
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
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
      ? Colors.red.shade400
      : taskData.priority == 'Medium'
          ? Colors.orange.shade400
          : Colors.blueGrey.shade400;

  return Card(
    elevation: 2.0,
    margin: const EdgeInsets.symmetric(vertical: 4.0),
    shadowColor: Colors.black.withOpacity(0.05),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        manager.send(EntityTapEvent(id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: taskData.isCompleted
                    ? Colors.deepPurple
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: taskData.isCompleted
                      ? Colors.deepPurple
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: taskData.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskData.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: taskData.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color:
                          taskData.isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assigned to: ${taskData.assignedTo}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                taskData.priority,
                style: TextStyle(
                    color: priorityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
