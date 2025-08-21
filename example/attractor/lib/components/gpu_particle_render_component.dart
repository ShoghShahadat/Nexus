import 'dart:typed_data';
import 'package:nexus/nexus.dart';

/// A component to hold the final, flattened data of all particles
/// ready to be rendered by the UI.
class GpuParticleRenderComponent extends Component with SerializableComponent {
  /// A flat list containing particle data for rendering.
  /// Layout: [x1, y1, size1, color1, x2, y2, size2, color2, ...]
  final Float32List particleData;

  GpuParticleRenderComponent(this.particleData);

  // Note: Serialization of Float32List is possible but can be inefficient.
  // For this example, we'll serialize it as a plain list of doubles.
  factory GpuParticleRenderComponent.fromJson(Map<String, dynamic> json) {
    return GpuParticleRenderComponent(
      Float32List.fromList(
          (json['particleData'] as List).cast<double>().toList()),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'particleData': particleData.toList(),
      };

  @override
  List<Object?> get props => [particleData];
}
