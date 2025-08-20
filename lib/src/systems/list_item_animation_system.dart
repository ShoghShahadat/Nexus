import 'package:flutter/animation.dart' show Curves;
import 'package:nexus/nexus.dart';

/// A system responsible for running animations on list items, such as the
/// exit animation when an item is deleted.
/// سیستمی که مسئول اجرای انیمیشن‌ها روی آیتم‌های لیست است، مانند انیمیشن
/// خروج هنگام حذف یک آیتم.
class ListItemAnimationSystem extends System {
  @override
  bool matches(Entity entity) {
    // It looks for items that are marked for animation but don't have an
    // active animation component yet.
    // به دنبال آیتم‌هایی می‌گردد که برای انیمیشن علامت‌گذاری شده‌اند اما هنوز
    // کامپوننت انیمیشن فعال ندارند.
    return entity.has<AnimateOutComponent>() &&
        !entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    // Create and add the exit animation.
    // انیمیشن خروج را ایجاد و اضافه می‌کند.
    entity.add(AnimationComponent(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      onUpdate: (e, value) {
        // This animation simply drives the AnimationProgressComponent.
        // The UI layer (FlutterRenderingSystem) will use this progress
        // value to create a fade or slide transition.
        // این انیمیشن فقط AnimationProgressComponent را هدایت می‌کند.
        // لایه UI از این مقدار پیشرفت برای ایجاد یک انتقال fade یا slide استفاده خواهد کرد.
        e.add(AnimationProgressComponent(
            1.0 - value)); // Progress from 1.0 down to 0.0
      },
      onComplete: (e) {
        // After the animation, fire an event to permanently remove the item's data.
        // پس از انیمیشن، رویدادی برای حذف دائمی داده‌های آیتم ارسال می‌کند.
        world.eventBus.fire(PurgeListItemEvent(e.id));
        // Finally, remove the entity itself from the world.
        // در نهایت، خود موجودیت را از دنیا حذف می‌کند.
        world.removeEntity(e.id);
      },
    ));
  }
}
