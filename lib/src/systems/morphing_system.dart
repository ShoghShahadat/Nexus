import 'dart:math';
import 'dart:ui';

import 'package:nexus/nexus.dart';

/// A system that drives path morphing animations.
///
/// This system looks for entities with a [MorphingComponent] that don't
/// already have an [AnimationComponent]. It then creates and adds an
/// animation to drive the morphing process, using a custom lerp function
/// to interpolate between the initial and target paths.
class MorphingSystem extends System {
  @override
  bool matches(Entity entity) {
    // We only want to start a new morph if one isn't already in progress.
    return entity.has<MorphingComponent>() && !entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // The logic is event-driven; when a MorphingComponent is added,
    // we add an AnimationComponent to process it.
    final morph = entity.get<MorphingComponent>()!;

    entity.add(AnimationComponent(
      duration: morph.duration,
      curve: morph.curve,
      onUpdate: (e, value) {
        // `value` is the animation progress from 0.0 to 1.0.
        // Use our custom lerp function to find the intermediate shape.
        final morphed = _lerpPaths(morph.initialPath, morph.targetPath, value);
        morph.currentPath = morphed;
        // Re-add the component to notify the renderer.
        e.add(morph);
      },
      onComplete: (e) {
        // When done, replace the morph component with one where the
        // initial and current paths are set to the final target shape.
        // This solidifies the shape in its final state.
        final finalMorph = MorphingComponent(
          initialPath: morph.targetPath,
          targetPath: morph.targetPath,
        );
        e.add(finalMorph);
      },
    ));
  }
}

/// A custom path interpolation function since `Path.lerp` is not available.
///
/// This function samples points along both paths and linearly interpolates
/// between them to create a new path. This is a simplified approach and
/// works best when paths have a single contour.
Path _lerpPaths(Path path1, Path path2, double t) {
  final newPath = Path();
  final metrics1 = path1.computeMetrics().toList();
  final metrics2 = path2.computeMetrics().toList();

  // This implementation only supports single-contour paths for simplicity.
  if (metrics1.isEmpty || metrics2.isEmpty) {
    // Return the target path if one is empty, which is a reasonable fallback.
    return t < 0.5 ? path1 : path2;
  }

  final metric1 = metrics1.first;
  final metric2 = metrics2.first;
  final length1 = metric1.length;
  final length2 = metric2.length;

  // We use a fixed number of samples for consistency.
  const sampleCount = 100;

  for (int i = 0; i <= sampleCount; i++) {
    final double progress = i / sampleCount;
    final Tangent? tangent1 = metric1.getTangentForOffset(progress * length1);
    final Tangent? tangent2 = metric2.getTangentForOffset(progress * length2);

    if (tangent1 != null && tangent2 != null) {
      final lerpedPosition =
          Offset.lerp(tangent1.position, tangent2.position, t)!;

      if (i == 0) {
        newPath.moveTo(lerpedPosition.dx, lerpedPosition.dy);
      } else {
        newPath.lineTo(lerpedPosition.dx, lerpedPosition.dy);
      }
    }
  }

  // If the target path is closed, we should close our new path too.
  if (metric2.isClosed) {
    newPath.close();
  }

  return newPath;
}
