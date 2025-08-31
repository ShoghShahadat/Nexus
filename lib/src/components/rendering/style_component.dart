import 'package:nexus/nexus.dart';
import 'package:flutter/painting.dart'
    show PaintingStyle, StrokeCap, StrokeJoin;
import 'package:meta/meta.dart';

/// Base class for serializable color representations (solid, gradient, etc.).
@immutable
abstract class StyleColor with EquatableMixin, SerializableComponent {
  const StyleColor();
  String get type;

  factory StyleColor.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'solid':
        return SolidColor.fromJson(json);
      case 'gradient':
        return GradientColor.fromJson(json);
      default:
        throw ArgumentError('Unknown StyleColor type: ${json['type']}');
    }
  }
}

class SolidColor extends StyleColor {
  final int value; // Stored as ARGB int e.g., 0xAARRGGBB

  const SolidColor(this.value);

  @override
  String get type => 'solid';

  factory SolidColor.fromJson(Map<String, dynamic> json) {
    return SolidColor(json['value'] as int);
  }

  @override
  Map<String, dynamic> toJson() => {'type': type, 'value': value};

  @override
  List<Object?> get props => [value];
}

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
  String get type => 'gradient';

  factory GradientColor.fromJson(Map<String, dynamic> json) {
    return GradientColor(
      colors: (json['colors'] as List).cast<int>(),
      stops: (json['stops'] as List).cast<double>(),
      beginX: (json['beginX'] as num).toDouble(),
      beginY: (json['beginY'] as num).toDouble(),
      endX: (json['endX'] as num).toDouble(),
      endY: (json['endY'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'colors': colors,
        'stops': stops,
        'beginX': beginX,
        'beginY': beginY,
        'endX': endX,
        'endY': endY,
      };

  @override
  List<Object?> get props => [colors, stops, beginX, beginY, endX, endY];
}

/// A serializable component that describes the paint style for a drawable entity.
class StyleComponent extends Component with SerializableComponent {
  final PaintingStyle style;
  final StyleColor color;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final double opacity; // *** NEW: Added for animation capabilities ***

  StyleComponent({
    this.style = PaintingStyle.fill,
    required this.color,
    this.strokeWidth = 1.0,
    this.strokeCap = StrokeCap.butt,
    this.strokeJoin = StrokeJoin.miter,
    this.opacity = 1.0, // *** NEW ***
  });

  factory StyleComponent.fromJson(Map<String, dynamic> json) {
    return StyleComponent(
      style: PaintingStyle.values[json['style'] as int],
      color: StyleColor.fromJson(json['color']),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      strokeCap: StrokeCap.values[json['strokeCap'] as int],
      strokeJoin: StrokeJoin.values[json['strokeJoin'] as int],
      opacity: (json['opacity'] as num? ?? 1.0).toDouble(), // *** NEW ***
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'style': style.index,
        'color': color.toJson(),
        'strokeWidth': strokeWidth,
        'strokeCap': strokeCap.index,
        'strokeJoin': strokeJoin.index,
        'opacity': opacity, // *** NEW ***
      };

  @override
  List<Object?> get props =>
      [style, color, strokeWidth, strokeCap, strokeJoin, opacity];
}
