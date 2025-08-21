import 'package:nexus/src/core/utils/equatable_mixin.dart';

/// A utility class for expressing frequency in a readable and intuitive way.
///
/// This class helps convert human-readable intervals (like "every 5 seconds")
/// into a standardized rate (events per second) used by systems like the SpawnerSystem.
class Frequency with EquatableMixin {
  /// The rate of events per second.
  final double eventsPerSecond;

  /// Creates a frequency based on a rate of events per second.
  const Frequency.perSecond(this.eventsPerSecond);

  /// Creates a frequency based on a rate of events per minute.
  const Frequency.perMinute(double eventsPerMinute)
      : eventsPerSecond = eventsPerMinute / 60.0;

  /// Creates a frequency based on a time interval.
  /// For example, `Frequency.every(const Duration(seconds: 5))` creates a
  /// frequency that fires once every 5 seconds (0.2 eventsPerSecond).
  factory Frequency.every(Duration duration) {
    if (duration.inMicroseconds <= 0) {
      // Return a very high frequency for zero or negative duration to avoid division by zero.
      // This represents continuous firing.
      return const Frequency.perSecond(double.maxFinite);
    }
    return Frequency.perSecond(
        1.0 / (duration.inMicroseconds / Duration.microsecondsPerSecond));
  }

  /// A frequency that never fires.
  static const Frequency never = Frequency.perSecond(0);

  @override
  List<Object?> get props => [eventsPerSecond];
}
