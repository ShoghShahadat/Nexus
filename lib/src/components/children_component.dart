import 'package:nexus/nexus.dart';

// *** NEW FILE ***
// This component has been moved from the example project into the core library
// as it represents a fundamental concept for hierarchical layouts.

/// Defines a hierarchical relationship between entities for layout purposes.
class ChildrenComponent extends Component with SerializableComponent {
  final List<EntityId> children;

  ChildrenComponent(this.children);

  factory ChildrenComponent.fromJson(Map<String, dynamic> json) {
    return ChildrenComponent(
      (json['children'] as List).map((e) => e as EntityId).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'children': children};

  @override
  List<Object?> get props => [children];
}
