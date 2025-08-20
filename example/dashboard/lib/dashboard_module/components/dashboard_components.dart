import 'package:nexus/nexus.dart';

// ... (Other components remain unchanged)

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
  final String description;
  final String createdDate;

  TaskItemComponent({
    required this.title,
    required this.assignedTo,
    required this.priority,
    required this.isCompleted,
    required this.description,
    required this.createdDate,
  });

  factory TaskItemComponent.fromJson(Map<String, dynamic> json) {
    return TaskItemComponent(
      title: json['title'] as String,
      assignedTo: json['assignedTo'] as String,
      priority: json['priority'] as String,
      isCompleted: json['isCompleted'] as bool,
      description: json['description'] as String,
      createdDate: json['createdDate'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'assignedTo': assignedTo,
        'priority': priority,
        'isCompleted': isCompleted,
        'description': description,
        'createdDate': createdDate,
      };

  @override
  List<Object?> get props =>
      [title, assignedTo, priority, isCompleted, description, createdDate];
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

/// A component to manage the expanded/collapsed state of a task.
class ExpandedStateComponent extends Component with SerializableComponent {
  final double progress;
  final bool isExpanding;

  ExpandedStateComponent({this.progress = 0.0, this.isExpanding = true});

  factory ExpandedStateComponent.fromJson(Map<String, dynamic> json) {
    return ExpandedStateComponent(
      progress: (json['progress'] as num).toDouble(),
      isExpanding: json['isExpanding'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {'progress': progress, 'isExpanding': isExpanding};

  @override
  List<Object?> get props => [progress, isExpanding];
}

/// A component for the high-frequency, real-time chart.
class RealtimeChartComponent extends Component with SerializableComponent {
  final List<double> data;
  // *** NEW: A counter for total frames processed. ***
  final int frameCount;

  RealtimeChartComponent(this.data, {this.frameCount = 0});

  factory RealtimeChartComponent.fromJson(Map<String, dynamic> json) {
    return RealtimeChartComponent(
      (json['data'] as List).map((e) => (e as num).toDouble()).toList(),
      frameCount: json['frameCount'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'data': data,
        'frameCount': frameCount,
      };

  @override
  List<Object?> get props => [data, frameCount];
}
