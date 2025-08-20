import 'package:nexus/nexus.dart';

/// A component that maintains a history of states for other components
/// on the same entity, enabling undo/redo functionality.
class HistoryComponent extends Component with SerializableComponent {
  /// A list of snapshots. Each snapshot is a map of component type names
  /// to their serialized JSON data.
  final List<Map<String, Map<String, dynamic>>> history;

  /// The index of the current state within the history list.
  final int currentIndex;

  /// The set of component type names (e.g., 'CounterStateComponent')
  /// that this component should track.
  final Set<String> trackedComponents;

  HistoryComponent({
    required this.trackedComponents,
    this.history = const [],
    this.currentIndex = -1,
  });

  factory HistoryComponent.fromJson(Map<String, dynamic> json) {
    // We need to handle nested maps correctly during deserialization.
    final historyList = (json['history'] as List)
        .map((snapshot) => (snapshot as Map).map(
              (key, value) => MapEntry(
                key as String,
                Map<String, dynamic>.from(value as Map),
              ),
            ))
        .toList();

    return HistoryComponent(
      history: historyList,
      currentIndex: json['currentIndex'] as int,
      trackedComponents:
          (json['trackedComponents'] as List).cast<String>().toSet(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'history': history,
        'currentIndex': currentIndex,
        'trackedComponents': trackedComponents.toList(),
      };

  @override
  List<Object?> get props => [history, currentIndex, trackedComponents];

  /// Returns true if an undo operation is possible.
  bool get canUndo => currentIndex > 0;

  /// Returns true if a redo operation is possible.
  bool get canRedo => currentIndex < history.length - 1;
}
