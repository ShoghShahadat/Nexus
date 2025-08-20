import 'package:flutter/animation.dart' show Curves, Curve;
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/decoration_components.dart';

/// A system that drives animations for `DecorationComponent`.
/// سیستمی که انیمیشن‌ها را برای `DecorationComponent` هدایت می‌کند.
///
/// It looks for entities with a `DecorationComponent` that has its `animateTo`
/// property set, and then creates a standard `AnimationComponent` to drive
//  an `AnimationProgressComponent`. The actual visual interpolation happens
/// in the `FlutterRenderingSystem`.
/// این سیستم به دنبال موجودیت‌هایی با `DecorationComponent` می‌گردد که پراپرتی `animateTo`
/// آن‌ها تنظیم شده باشد، و سپس یک `AnimationComponent` استاندارد برای هدایت یک
/// `AnimationProgressComponent` ایجاد می‌کند. درون‌یابی بصری واقعی در
/// `FlutterRenderingSystem` اتفاق می‌افتد.
class DecorationAnimationSystem extends System {
  // A map to convert string curve names to Curve objects.
  // مپی برای تبدیل نام‌های رشته‌ای curve به آبجکت‌های Curve.
  static const Map<String, Curve> _stringToCurve = {
    'linear': Curves.linear,
    'ease': Curves.ease,
    'easeIn': Curves.easeIn,
    'easeOut': Curves.easeOut,
    'easeInOut': Curves.easeInOut,
  };

  @override
  bool matches(Entity entity) {
    final deco = entity.get<DecorationComponent>();
    // Match if the component has an animation target but no active animation.
    // اگر کامپوننت یک هدف انیمیشن داشته باشد اما انیمیشن فعالی نداشته باشد، مچ می‌شود.
    return deco != null &&
        deco.animateTo != null &&
        !entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final deco = entity.get<DecorationComponent>()!;

    entity.add(AnimationComponent(
      duration: Duration(milliseconds: deco.animationDurationMs ?? 1000),
      curve: _stringToCurve[deco.animationCurve] ?? Curves.linear,
      onUpdate: (e, value) {
        e.add(AnimationProgressComponent(value));
      },
      onComplete: (e) {
        // When animation finishes, replace the current decoration with the target one.
        // وقتی انیمیشن تمام شد، دکوراسیون فعلی را با دکوراسیون هدف جایگزین می‌کند.
        e.add(deco.animateTo!);
        e.remove<AnimationProgressComponent>();
      },
    ));
  }
}
