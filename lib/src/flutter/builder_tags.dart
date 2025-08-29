/// A centralized class for defining type-safe tags used to map entities
/// to their corresponding widget builders in the FlutterRenderingSystem.
///
/// Using static constants instead of raw strings prevents typos and allows
/// for better code completion and compile-time safety.
class BuilderTags {
  /// A tag for the main counter display, which has complex custom painting logic.
  static const String counterDisplay = 'counter_display';

  /// A generic tag for any entity that should be rendered by the data-driven
  /// CustomWidgetBuilder.
  static const String customWidget = 'custom_widget';

  static const String root = 'root';

  /// A conventional tag for the main application bar entity.
  static const String appBar = 'app_bar';

  /// A conventional tag for the main body or content area entity.
  static const String body = 'body';

  /// A conventional tag for the navigation drawer or panel entity.
  static const String navigationPanel = 'navigation_panel';
}
