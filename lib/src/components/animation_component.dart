import 'package:flutter/animation.dart' show Curve;
import 'package:nexus/src/core/component.dart';
import 'package:nexus/src/core/entity.dart';

/// A component that drives animations on an entity.
///
/// This component holds the configuration for an animation, such as its
/// duration, curve, and the logic to apply the animated value to other
/// components on the entity.
class AnimationComponent extends Component {
  /// The total duration of the animation.
  final Duration duration;

  /// The curve to apply to the animation's progress.
  final Curve curve;

  /// A callback executed on each frame of the animation.
  ///
  /// The [value] parameter is the interpolated progress of the animation
  /// (from 0.0 to 1.0) after the curve has been applied.
  /// The [entity] is the entity being animated.
  final void Function(Entity entity, double value) onUpdate;

  /// An optional callback executed when the animation completes.
  final void Function(Entity entity)? onComplete;

  /// If true, the animation starts automatically when the entity is added.
  final bool autostart;

  /// If true, the animation will restart upon completion.
  final bool repeat;

  /// If true, the component will be removed from the entity once the
  /// animation is complete (and not repeating).
  final bool removeOnComplete;

  // Internal state
  double _elapsed = 0.0;
  bool _isFinished = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  bool get isFinished => _isFinished;

  AnimationComponent({
    required this.duration,
    required this.curve,
    required this.onUpdate,
    this.onComplete,
    this.autostart = true,
    this.repeat = false,
    this.removeOnComplete = true,
  }) {
    if (autostart) {
      _isPlaying = true;
    }
  }

  /// Starts the animation.
  void play() {
    _isPlaying = true;
  }

  /// Pauses the animation.
  void pause() {
    _isPlaying = false;
  }

  /// Resets the animation to its beginning.
  void reset() {
    _elapsed = 0.0;
    _isFinished = false;
    if (autostart) {
      _isPlaying = true;
    } else {
      _isPlaying = false;
    }
  }

  /// Internal method to update the animation's progress.
  /// Called by the [AnimationSystem].
  void update(double dt) {
    if (!_isPlaying || _isFinished) return;

    _elapsed += dt;
    final double t =
        (_elapsed / duration.inMilliseconds * 1000).clamp(0.0, 1.0);

    if (t >= 1.0) {
      _isFinished = true;
      _isPlaying = false;
    }
  }

  /// Internal method to get the current curved value.
  /// Called by the [AnimationSystem].
  double get curvedValue => curve
      .transform((_elapsed / duration.inMilliseconds * 1000).clamp(0.0, 1.0));
}
