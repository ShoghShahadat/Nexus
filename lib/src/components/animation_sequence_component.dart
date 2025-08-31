import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';

/// یک کلاس داده که یک "قطعه" از یک سکانس انیمیشن را تعریف می‌کند.
class Tween with EquatableMixin {
  final Type targetComponentType;
  final Map<String, dynamic> properties;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  Tween({
    required this.targetComponentType,
    required this.properties,
    this.duration = const Duration(seconds: 1),
    this.delay = Duration.zero,
    this.curve = Curves.linear,
  });

  @override
  List<Object?> get props => [
        targetComponentType,
        const DeepCollectionEquality().hash(properties),
        duration,
        delay,
        curve
      ];
}

/// کامپوننتی که یک صف از انیمیشن‌ها را برای اجرای متوالی توسط
/// NexusAnimatorSystem نگهداری می‌کند.
class AnimationSequenceComponent extends Component {
  final List<Tween> tweens;

  // وضعیت داخلی که توسط سیستم مدیریت می‌شود
  final bool isPlaying;
  final double elapsedDelay;

  AnimationSequenceComponent(
    this.tweens, {
    this.isPlaying = false,
    this.elapsedDelay = 0.0,
  });

  @override
  List<Object?> get props => [tweens, isPlaying, elapsedDelay];
}

/// یک کلاس سازنده (Builder) با API روان برای ساخت آسان
/// AnimationSequenceComponent.
class AnimationSequence {
  final List<Tween> _tweens = [];

  AnimationSequence._();

  /// ساخت یک سکانس جدید را آغاز می‌کند.
  static AnimationSequence start() {
    return AnimationSequence._();
  }

  /// یک قطعه انیمیشن جدید به سکانس اضافه می‌کند.
  AnimationSequence tween<T extends Component>({
    required Map<String, dynamic> properties,
    Duration duration = const Duration(seconds: 1),
    Curve curve = Curves.linear,
  }) {
    _tweens.add(Tween(
      targetComponentType: T,
      properties: properties,
      duration: duration,
      curve: curve,
    ));
    return this;
  }

  /// یک تأخیر به سکانس اضافه می‌کند.
  AnimationSequence delay(Duration duration) {
    // تأخیر به عنوان یک Tween بدون پراپرتی پیاده‌سازی می‌شود.
    _tweens.add(Tween(
      targetComponentType: Null, // نوع خاص برای نشان دادن تأخیر
      properties: {},
      duration: duration,
    ));
    return this;
  }

  /// کامپوننت نهایی را برای افزودن به یک موجودیت می‌سازد.
  AnimationSequenceComponent build() {
    return AnimationSequenceComponent(_tweens);
  }
}
