import 'package:nexus/nexus.dart';
import 'dart:ui' show lerpDouble;

import 'package:nexus/src/components/animation_sequence_component.dart';

/// یک سیستم سطح بالا که سکانس‌های انیمیشن را برای موجودیت‌ها ارکستراسیون می‌کند.
/// این سیستم به طور خودکار انیمیشن‌ها را از یک صف اجرا کرده و مدیریت می‌کند.
class NexusAnimatorSystem extends UpdateSystem {
  @override
  bool matches(Entity entity) {
    // به دنبال موجودیتی می‌گردیم که سکانس انیمیشن دارد اما در حال حاضر
    // توسط یک AnimationComponent فعال، مدیریت نمی‌شود.
    return entity.has<AnimationSequenceComponent>() &&
        !entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final sequenceComp = entity.get<AnimationSequenceComponent>()!;
    if (sequenceComp.tweens.isEmpty) {
      // اگر سکانس تمام شده، کامپوننت را حذف کن.
      entity.remove<AnimationSequenceComponent>();
      return;
    }

    var currentTween = sequenceComp.tweens.first;

    // مدیریت تأخیر
    if (currentTween.targetComponentType == Null) {
      var elapsed = sequenceComp.elapsedDelay + dt;
      if (elapsed >= currentTween.duration.inMilliseconds / 1000.0) {
        // تأخیر تمام شد، این tween را از صف حذف کن.
        final remainingTweens = List<Tween>.from(sequenceComp.tweens)
          ..removeAt(0);
        entity.add(AnimationSequenceComponent(remainingTweens));
      } else {
        // هنوز در حال تأخیر هستیم، زمان سپری شده را به‌روز کن.
        entity.add(AnimationSequenceComponent(sequenceComp.tweens,
            elapsedDelay: elapsed));
      }
      return;
    }

    // گرفتن کامپوننت هدف برای انیمیشن
    final targetComponent = entity.getByType(currentTween.targetComponentType);
    if (targetComponent == null || targetComponent is! SerializableComponent) {
      // اگر کامپوننت هدف وجود ندارد یا قابل سریال‌سازی نیست، از این tween صرف نظر کن.
      final remainingTweens = List<Tween>.from(sequenceComp.tweens)
        ..removeAt(0);
      entity.add(AnimationSequenceComponent(remainingTweens));
      return;
    }

    // گرفتن مقادیر اولیه از کامپوننت فعلی
    final startJson = (targetComponent as SerializableComponent).toJson();
    final startValues = <String, double>{};
    for (var key in currentTween.properties.keys) {
      startValues[key] = (startJson[key] as num? ?? 0.0).toDouble();
    }

    // ایجاد AnimationComponent برای اجرای این قطعه از سکانس
    entity.add(AnimationComponent(
      duration: currentTween.duration,
      curve: currentTween.curve,
      onUpdate: (e, value) {
        final newProperties = <String, dynamic>{};
        for (var key in currentTween.properties.keys) {
          final startVal = startValues[key]!;
          final endVal = (currentTween.properties[key] as num).toDouble();
          newProperties[key] = lerpDouble(startVal, endVal, value);
        }
        // استفاده از copyWith برای اعمال تغییرات به صورت immutable
        e.add(targetComponent.copyWith(newProperties));
      },
      onComplete: (e) {
        // پس از اتمام، این tween را از صف حذف کرده و AnimationComponent را پاک می‌کنیم.
        // این کار باعث می‌شود سیستم در فریم بعدی، tween بعدی را اجرا کند.
        final remainingTweens = List<Tween>.from(sequenceComp.tweens)
          ..removeAt(0);
        e.add(AnimationSequenceComponent(remainingTweens));
        e.remove<AnimationComponent>();
      },
    ));
  }
}
