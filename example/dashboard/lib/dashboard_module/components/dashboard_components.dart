import 'package:nexus/nexus.dart';

// *** FIX: ChildrenComponent has been removed from this file. ***
// It is now part of the core Nexus library.

/// Component for holding the data of a summary card.
class SummaryCardComponent extends Component with SerializableComponent {
  final String title;
  final String value;
  final int iconCodePoint;
  final int colorValue;

  SummaryCardComponent({
    required this.title,
    required this.value,
    required this.iconCodePoint,
    required this.colorValue,
  });

  factory SummaryCardComponent.fromJson(Map<String, dynamic> json) {
    return SummaryCardComponent(
      title: json['title'] as String,
      value: json['value'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
      };

  @override
  List<Object?> get props => [title, value, iconCodePoint, colorValue];
}

/// Component for holding the data of the bar chart.
class ChartDataComponent extends Component with SerializableComponent {
  final String title;
  final List<double> weeklyData;

  ChartDataComponent({required this.title, required this.weeklyData});

  factory ChartDataComponent.fromJson(Map<String, dynamic> json) {
    return ChartDataComponent(
      title: json['title'] as String,
      weeklyData: (json['weeklyData'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'weeklyData': weeklyData,
      };

  @override
  List<Object?> get props => [title, weeklyData];
}

/// Component for holding the data of a task list item.
class TaskItemComponent extends Component with SerializableComponent {
  final String title;
  final String assignedTo;
  final String priority;
  final bool isCompleted;

  TaskItemComponent({
    required this.title,
    required this.assignedTo,
    required this.priority,
    required this.isCompleted,
  });

  factory TaskItemComponent.fromJson(Map<String, dynamic> json) {
    return TaskItemComponent(
      title: json['title'] as String,
      assignedTo: json['assignedTo'] as String,
      priority: json['priority'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'assignedTo': assignedTo,
        'priority': priority,
        'isCompleted': isCompleted,
      };

  @override
  List<Object?> get props => [title, assignedTo, priority, isCompleted];
}

/// A simple animation component for entry states (fade-in, slide-in).
class EntryAnimationComponent extends Component with SerializableComponent {
  final double delay;

  EntryAnimationComponent({required this.delay});

  factory EntryAnimationComponent.fromJson(Map<String, dynamic> json) {
    return EntryAnimationComponent(
      delay: (json['delay'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'delay': delay};

  @override
  List<Object?> get props => [delay];
}
