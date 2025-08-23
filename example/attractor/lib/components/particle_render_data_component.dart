import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

class RenderableParticle with EquatableMixin, SerializableComponent {
  final double x;
  final double y;
  final double radius;
  final int colorValue;

  RenderableParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.colorValue,
  });

  @override
  List<Object?> get props => [x, y, radius, colorValue];

  factory RenderableParticle.fromJson(Map<String, dynamic> json) {
    return RenderableParticle(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'radius': radius,
        'colorValue': colorValue,
      };
}

class ParticleRenderDataComponent extends Component with SerializableComponent {
  final List<RenderableParticle> particles;

  ParticleRenderDataComponent(this.particles);

  factory ParticleRenderDataComponent.fromJson(Map<String, dynamic> json) {
    return ParticleRenderDataComponent(
      (json['particles'] as List)
          .map((p) => RenderableParticle.fromJson(p))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'particles': particles.map((p) => p.toJson()).toList(),
      };

  @override
  List<Object?> get props => [particles];
}
