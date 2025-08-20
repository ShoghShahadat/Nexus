import 'package:nexus/nexus.dart';

/// A data-driven component that provides a blueprint for building a custom widget on the UI thread.
///
/// This component allows the logic isolate to define the type and properties of a widget
/// without being coupled to Flutter's widget classes.
class CustomWidgetComponent extends Component with SerializableComponent {
  /// A string key that identifies the type of widget to build (e.g., 'elevated_button', 'text').
  final String widgetType;

  /// A map of properties to configure the widget (e.g., {'text': 'Click Me', 'color': 0xFFFFFFFF}).
  final Map<String, dynamic> properties;

  CustomWidgetComponent({required this.widgetType, this.properties = const {}});

  factory CustomWidgetComponent.fromJson(Map<String, dynamic> json) {
    return CustomWidgetComponent(
      widgetType: json['widgetType'] as String,
      properties: Map<String, dynamic>.from(json['properties']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'widgetType': widgetType,
        'properties': properties,
      };

  @override
  List<Object?> get props => [widgetType, properties];
}
