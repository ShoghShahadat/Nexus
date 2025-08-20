import 'package:nexus/nexus.dart';

// --- Helper Classes for Styling ---

/// A base class for representing color, allowing for solid or gradient types.
/// یک کلاس پایه برای نمایش رنگ که می‌تواند از نوع ثابت یا گرادینت باشد.
abstract class StyleColor with EquatableMixin, SerializableComponent {
  const StyleColor();

  factory StyleColor.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'solid':
        return SolidColor.fromJson(json);
      case 'gradient':
        return GradientColor.fromJson(json);
      default:
        throw ArgumentError('Unknown StyleColor type');
    }
  }
}

/// Represents a single, solid color.
/// یک رنگ ثابت و تنها را نشان می‌دهد.
class SolidColor extends StyleColor {
  final int value; // e.g., 0xFFFFFFFF

  const SolidColor(this.value);

  @override
  Map<String, dynamic> toJson() => {'type': 'solid', 'value': value};

  factory SolidColor.fromJson(Map<String, dynamic> json) =>
      SolidColor(json['value']);

  @override
  List<Object?> get props => [value];
}

/// Represents a linear gradient color.
/// یک رنگ گرادینت خطی را نشان می‌دهد.
class GradientColor extends StyleColor {
  final List<int> colors;
  final List<double> stops;
  final double beginX, beginY, endX, endY;

  const GradientColor({
    required this.colors,
    required this.stops,
    this.beginX = -1.0,
    this.beginY = 0.0,
    this.endX = 1.0,
    this.endY = 0.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'gradient',
        'colors': colors,
        'stops': stops,
        'beginX': beginX,
        'beginY': beginY,
        'endX': endX,
        'endY': endY,
      };

  factory GradientColor.fromJson(Map<String, dynamic> json) => GradientColor(
        colors: (json['colors'] as List).cast<int>(),
        stops: (json['stops'] as List).cast<double>(),
        beginX: (json['beginX'] as num).toDouble(),
        beginY: (json['beginY'] as num).toDouble(),
        endX: (json['endX'] as num).toDouble(),
        endY: (json['endY'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [colors, stops, beginX, beginY, endX, endY];
}

/// A serializable representation of a box shadow.
/// یک نمایش سریالایزبل از سایه باکس.
class BoxShadowStyle with EquatableMixin, SerializableComponent {
  final int color;
  final double offsetX, offsetY, blurRadius, spreadRadius;

  const BoxShadowStyle({
    this.color = 0xFF000000,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.blurRadius = 0.0,
    this.spreadRadius = 0.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'color': color,
        'offsetX': offsetX,
        'offsetY': offsetY,
        'blurRadius': blurRadius,
        'spreadRadius': spreadRadius,
      };

  factory BoxShadowStyle.fromJson(Map<String, dynamic> json) => BoxShadowStyle(
        color: json['color'],
        offsetX: (json['offsetX'] as num).toDouble(),
        offsetY: (json['offsetY'] as num).toDouble(),
        blurRadius: (json['blurRadius'] as num).toDouble(),
        spreadRadius: (json['spreadRadius'] as num).toDouble(),
      );

  @override
  List<Object?> get props =>
      [color, offsetX, offsetY, blurRadius, spreadRadius];
}

// --- Main Decoration Component ---

/// A data-driven component for describing the decoration of a widget.
/// یک کامپوننت داده-محور برای توصیف دکوراسیون یک ویجت.
///
/// It can describe background color/gradient, borders, and shadows, and can
/// be animated by the `DecorationAnimationSystem`.
/// این کامپوننت می‌تواند رنگ پس‌زمینه، حاشیه و سایه را توصیف کند و توسط
/// `DecorationAnimationSystem` انیمیشن داده شود.
class DecorationComponent extends Component with SerializableComponent {
  final StyleColor? color;
  final List<BoxShadowStyle>? boxShadow;
  // Note: Border properties can be added here in the future.
  // نکته: ویژگی‌های مربوط به حاشیه (Border) می‌توانند در آینده اینجا اضافه شوند.

  // --- Animation Properties ---
  /// The target decoration state to animate towards.
  /// وضعیت دکوراسیون مقصد برای انیمیشن.
  final DecorationComponent? animateTo;
  final int? animationDurationMs;
  final String? animationCurve; // e.g., 'easeOut'

  DecorationComponent({
    this.color,
    this.boxShadow,
    this.animateTo,
    this.animationDurationMs,
    this.animationCurve,
  });

  factory DecorationComponent.fromJson(Map<String, dynamic> json) {
    return DecorationComponent(
      color: json['color'] != null ? StyleColor.fromJson(json['color']) : null,
      boxShadow: (json['boxShadow'] as List?)
          ?.map((s) => BoxShadowStyle.fromJson(s))
          .toList(),
      animateTo: json['animateTo'] != null
          ? DecorationComponent.fromJson(json['animateTo'])
          : null,
      animationDurationMs: json['animationDurationMs'],
      animationCurve: json['animationCurve'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'color': color?.toJson(),
        'boxShadow': boxShadow?.map((s) => s.toJson()).toList(),
        'animateTo': animateTo?.toJson(),
        'animationDurationMs': animationDurationMs,
        'animationCurve': animationCurve,
      };

  @override
  List<Object?> get props =>
      [color, boxShadow, animateTo, animationDurationMs, animationCurve];
}
