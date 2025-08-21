import 'package:nexus/nexus.dart';

/// A serializable component to hold real-time debug and performance metrics.
class DebugInfoComponent extends Component with SerializableComponent {
  final double fps;
  final double frameTime;
  final int entityCount;
  final String gpuMode;

  DebugInfoComponent({
    this.fps = 0.0,
    this.frameTime = 0.0,
    this.entityCount = 0,
    this.gpuMode = 'N/A',
  });

  factory DebugInfoComponent.fromJson(Map<String, dynamic> json) {
    return DebugInfoComponent(
      fps: (json['fps'] as num).toDouble(),
      frameTime: (json['frameTime'] as num).toDouble(),
      entityCount: json['entityCount'] as int,
      gpuMode: json['gpuMode'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'fps': fps,
        'frameTime': frameTime,
        'entityCount': entityCount,
        'gpuMode': gpuMode,
      };

  @override
  List<Object?> get props => [fps, frameTime, entityCount, gpuMode];
}
