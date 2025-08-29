import 'package:flutter/painting.dart' show PathFillType;
import 'package:nexus/nexus.dart';
import 'package:meta/meta.dart';

/// Base class for all shape descriptions. These are pure, serializable data objects.
@immutable
abstract class Shape with EquatableMixin, SerializableComponent {
  const Shape();

  // A type identifier used for deserialization.
  String get type;

  factory Shape.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'rectangle':
        return RectangleShape.fromJson(json);
      case 'circle':
        return CircleShape.fromJson(json);
      case 'line':
        return LineShape.fromJson(json);
      case 'path':
        return PathShape.fromJson(json);
      // Add other shapes here
      default:
        throw ArgumentError('Unknown Shape type: ${json['type']}');
    }
  }
}

/// A component that holds a declarative description of a shape.
class ShapeComponent extends Component with SerializableComponent {
  final Shape shape;

  ShapeComponent(this.shape);

  factory ShapeComponent.fromJson(Map<String, dynamic> json) {
    return ShapeComponent(Shape.fromJson(json['shape']));
  }

  @override
  Map<String, dynamic> toJson() => {'shape': shape.toJson()};

  @override
  List<Object?> get props => [shape];
}

// --- Concrete Shape Implementations ---

class RectangleShape extends Shape {
  final double x;
  final double y;
  final double width;
  final double height;
  final double cornerRadius;

  const RectangleShape({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.cornerRadius = 0.0,
  });

  @override
  String get type => 'rectangle';

  factory RectangleShape.fromJson(Map<String, dynamic> json) {
    return RectangleShape(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      cornerRadius: (json['cornerRadius'] as num? ?? 0.0).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'cornerRadius': cornerRadius,
      };

  @override
  List<Object?> get props => [x, y, width, height, cornerRadius];
}

class CircleShape extends Shape {
  final double centerX;
  final double centerY;
  final double radius;

  const CircleShape({
    required this.centerX,
    required this.centerY,
    required this.radius,
  });

  @override
  String get type => 'circle';

  factory CircleShape.fromJson(Map<String, dynamic> json) {
    return CircleShape(
      centerX: (json['centerX'] as num).toDouble(),
      centerY: (json['centerY'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'centerX': centerX,
        'centerY': centerY,
        'radius': radius,
      };

  @override
  List<Object?> get props => [centerX, centerY, radius];
}

class LineShape extends Shape {
  final double x1, y1, x2, y2;

  const LineShape({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  @override
  String get type => 'line';

  factory LineShape.fromJson(Map<String, dynamic> json) {
    return LineShape(
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
      };

  @override
  List<Object?> get props => [x1, y1, x2, y2];
}

/// A serializable description of a path command.
@immutable
abstract class PathCommand with EquatableMixin {
  const PathCommand();
  String get command;

  factory PathCommand.fromJson(Map<String, dynamic> json) {
    switch (json['command']) {
      case 'moveTo':
        return MoveToCommand.fromJson(json);
      case 'lineTo':
        return LineToCommand.fromJson(json);
      case 'close':
        return const CloseCommand();
      default:
        throw ArgumentError('Unknown PathCommand: ${json['command']}');
    }
  }
  Map<String, dynamic> toJson();
}

class MoveToCommand extends PathCommand {
  final double x, y;
  const MoveToCommand(this.x, this.y);
  @override
  String get command => 'moveTo';
  @override
  List<Object?> get props => [x, y];
  @override
  Map<String, dynamic> toJson() => {'command': command, 'x': x, 'y': y};
  factory MoveToCommand.fromJson(Map<String, dynamic> json) => MoveToCommand(
      (json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

class LineToCommand extends PathCommand {
  final double x, y;
  const LineToCommand(this.x, this.y);
  @override
  String get command => 'lineTo';
  @override
  List<Object?> get props => [x, y];
  @override
  Map<String, dynamic> toJson() => {'command': command, 'x': x, 'y': y};
  factory LineToCommand.fromJson(Map<String, dynamic> json) => LineToCommand(
      (json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

class CloseCommand extends PathCommand {
  const CloseCommand();
  @override
  String get command => 'close';
  @override
  List<Object?> get props => [];
  @override
  Map<String, dynamic> toJson() => {'command': command};
}
// Add other commands like `quadraticBezierTo`, `cubicTo`, `arcTo`, etc. here.

class PathShape extends Shape {
  final List<PathCommand> commands;
  final PathFillType fillType;

  const PathShape(
      {required this.commands, this.fillType = PathFillType.nonZero});

  @override
  String get type => 'path';

  factory PathShape.fromJson(Map<String, dynamic> json) {
    return PathShape(
      commands: (json['commands'] as List)
          .map((cmd) => PathCommand.fromJson(cmd))
          .toList(),
      fillType: PathFillType.values[json['fillType'] as int],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'commands': commands.map((cmd) => cmd.toJson()).toList(),
        'fillType': fillType.index,
      };

  @override
  List<Object?> get props => [commands, fillType];
}
