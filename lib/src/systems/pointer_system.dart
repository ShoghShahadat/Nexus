import 'dart:async'; // برای StreamSubscription
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/attractor_component.dart';
import 'package:nexus/src/events/pointer_events.dart'; // وارد کردن NexusPointerMoveEvent

/// A system that listens for pointer events from the UI and updates the
/// position of a designated entity (like the attractor).
class PointerSystem extends System {
  Entity? _trackedEntity;
  StreamSubscription?
      _pointerMoveSubscription; // اضافه کردن متغیر برای نگهداری اشتراک

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // گوش دادن به رویدادهای حرکت اشاره‌گر از UI.
    // نوع رویداد به NexusPointerMoveEvent تغییر یافت.
    _pointerMoveSubscription =
        world.eventBus.on<NexusPointerMoveEvent>(_onPointerMove);
    // Lazily find the entity later to ensure it has been added.
  }

  void _onPointerMove(NexusPointerMoveEvent event) {
    // نوع رویداد به NexusPointerMoveEvent تغییر یافت
    // پیدا کردن یا به‌روزرسانی Entity جاذب (attractor)
    // از firstWhere استفاده می‌کنیم و اگر پیدا نشد، یک Entity خالی برمی‌گردانیم
    // تا از null pointer exception جلوگیری شود.
    _trackedEntity ??= world.entities.values
        .firstWhere((e) => e.has<AttractorComponent>(), orElse: () => Entity());

    if (_trackedEntity!.has<AttractorComponent>()) {
      // دریافت کامپوننت موقعیت جاذب
      final pos = _trackedEntity!.get<PositionComponent>()!;
      // به‌روزرسانی موقعیت جاذب با موقعیت اشاره‌گر
      pos.x = event.x;
      pos.y = event.y;
      // دوباره اضافه کردن کامپوننت برای اطلاع‌رسانی به UI
      _trackedEntity!.add(pos);
    }
  }

  @override
  bool matches(Entity entity) =>
      false; // این سیستم رویدادمحور است و نیازی به پردازش در حلقه update ندارد.

  @override
  void update(Entity entity, double dt) {}

  @override
  void onRemovedFromWorld() {
    // لغو اشتراک زمانی که سیستم از World حذف می‌شود.
    _pointerMoveSubscription?.cancel();
    _pointerMoveSubscription = null;
    super.onRemovedFromWorld();
  }
}
