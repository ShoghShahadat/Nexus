import 'package:nexus/nexus.dart';

/// Defines the rebuilding behavior for an entity's widget in the UI.
enum RenderBehavior {
  /// Default behavior. The widget and its children are rebuilt when data changes.
  dynamicView,

  /// The widget's shell rebuilds, but its children are reused from the previous frame.
  /// Ideal for containers with animations (like borders) that shouldn't affect their content.
  staticShell,

  /// The widget and its entire descendant tree are built only once and then treated as constant.
  staticScope,
}

/// A component that instructs the FlutterRenderingSystem on how to rebuild the widget
/// associated with this entity. This provides fine-grained performance control.
/// This component is serializable.
class RenderStrategyComponent extends Component with SerializableComponent {
  final RenderBehavior behavior;

  RenderStrategyComponent(this.behavior);

  factory RenderStrategyComponent.fromJson(Map<String, dynamic> json) {
    return RenderStrategyComponent(
      RenderBehavior.values[json['behavior'] as int],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'behavior': behavior.index,
      };

  @override
  List<Object?> get props => [behavior];
}
