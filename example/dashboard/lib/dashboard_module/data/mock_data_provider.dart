import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nexus_example/dashboard_module/components/dashboard_components.dart';

/// This class is responsible for generating mock data for the dashboard.
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

  /// Generates a list of mock tasks with more details.
  List<TaskItemComponent> getTasks() {
    return [
      TaskItemComponent(
        title: 'Design the main application screen',
        assignedTo: 'Mr. Rezaei',
        priority: 'High',
        isCompleted: false,
        description:
            'Create mockups and prototypes for the main dashboard, including all UI components.',
        createdDate: '2024-08-15',
      ),
      TaskItemComponent(
        title: 'Implement the authentication mechanism',
        assignedTo: 'Ms. Ahmadi',
        priority: 'High',
        isCompleted: false,
        description:
            'Set up Firebase Authentication and create login/signup flows.',
        createdDate: '2024-08-12',
      ),
      TaskItemComponent(
        title: 'Connect to the payment API',
        assignedTo: 'Mr. Mohammadi',
        priority: 'Medium',
        isCompleted: true,
        description:
            'Integrate the Stripe API for handling payments and subscriptions.',
        createdDate: '2024-08-10',
      ),
      TaskItemComponent(
        title: 'Write unit tests for the user module',
        assignedTo: 'Ms. Sharifi',
        priority: 'Low',
        isCompleted: false,
        description:
            'Ensure at least 80% code coverage for all services and repositories in the user module.',
        createdDate: '2024-08-18',
      ),
      TaskItemComponent(
        title: 'Prepare project documentation',
        assignedTo: 'Mr. Karimi',
        priority: 'Medium',
        isCompleted: true,
        description:
            'Document the API endpoints and the overall architecture of the project.',
        createdDate: '2024-08-05',
      ),
      TaskItemComponent(
        title: 'Review and fix reported bugs',
        assignedTo: 'Ms. Ahmadi',
        priority: 'High',
        isCompleted: false,
        description:
            'Address all critical bugs reported in the last sprint from the QA team.',
        createdDate: '2024-08-19',
      ),
    ];
  }
}
