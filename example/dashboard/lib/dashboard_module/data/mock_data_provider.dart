import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';

/// This class is responsible for generating mock data for the dashboard.
/// In a real application, this data would come from an API, database, or another service.
class MockDataProvider {
  final Random _random = Random();

  /// Generates data for the summary cards.
  List<SummaryCardComponent> getSummaryCards() {
    return [
      SummaryCardComponent(
        title: 'Active Projects',
        value: '12',
        iconCodePoint: Icons.folder_open.codePoint,
        colorValue: Colors.blue.value,
      ),
      SummaryCardComponent(
        title: 'Completed Tasks',
        value: '87',
        iconCodePoint: Icons.check_circle_outline.codePoint,
        colorValue: Colors.green.value,
      ),
      SummaryCardComponent(
        title: 'Team Members',
        value: '28',
        iconCodePoint: Icons.people_outline.codePoint,
        colorValue: Colors.orange.value,
      ),
      SummaryCardComponent(
        title: 'System Alerts',
        value: '3',
        iconCodePoint: Icons.warning_amber_rounded.codePoint,
        colorValue: Colors.red.value,
      ),
    ];
  }

  /// Generates data for the weekly progress chart.
  ChartDataComponent getChartData() {
    return ChartDataComponent(
      title: 'Weekly Progress',
      weeklyData: List.generate(7, (_) => _random.nextDouble() * 100),
    );
  }

  /// Generates a list of mock tasks.
  List<TaskItemComponent> getTasks() {
    return [
      TaskItemComponent(
        title: 'Design the main application screen',
        assignedTo: 'Mr. Rezaei',
        priority: 'High',
        isCompleted: false,
      ),
      TaskItemComponent(
        title: 'Implement the authentication mechanism',
        assignedTo: 'Ms. Ahmadi',
        priority: 'High',
        isCompleted: false,
      ),
      TaskItemComponent(
        title: 'Connect to the payment API',
        assignedTo: 'Mr. Mohammadi',
        priority: 'Medium',
        isCompleted: true,
      ),
      TaskItemComponent(
        title: 'Write unit tests for the user module',
        assignedTo: 'Ms. Sharifi',
        priority: 'Low',
        isCompleted: false,
      ),
      TaskItemComponent(
        title: 'Prepare project documentation',
        assignedTo: 'Mr. Karimi',
        priority: 'Medium',
        isCompleted: true,
      ),
      TaskItemComponent(
        title: 'Review and fix reported bugs',
        assignedTo: 'Ms. Ahmadi',
        priority: 'High',
        isCompleted: false,
      ),
    ];
  }
}
