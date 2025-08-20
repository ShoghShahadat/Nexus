import 'package:nexus/nexus.dart';

/// An event fired from the UI thread to the logic isolate when an entity
/// is tapped. This is a simple data class to ensure it can be sent
/// across isolate boundaries.
/// رویدادی که هنگام ضربه زدن روی یک موجودیت، از ترد UI به isolate منطق ارسال می‌شود.
class EntityTapEvent {
  final EntityId id;

  EntityTapEvent(this.id);
}

/// An event fired when a keyboard key is pressed or released.
/// Renamed to avoid conflicts with Flutter's own KeyEvent.
/// رویدادی که هنگام فشرده یا رها شدن یک کلید کیبورد ارسال می‌شود.
/// برای جلوگیری از تداخل با KeyEvent خود فلاتر، تغییر نام داده شد.
class NexusKeyEvent {
  /// The unique logical identifier for the key.
  /// شناسه منطقی و یکتای کلید.
  final int logicalKeyId;

  /// The character produced by the key, if any.
  /// کاراکتری که توسط کلید تولید شده است (در صورت وجود).
  final String? character;

  /// True if the key is being pressed down.
  /// اگر کلید فشرده شده باشد، true است.
  final bool isKeyDown;

  NexusKeyEvent({
    required this.logicalKeyId,
    this.character,
    required this.isKeyDown,
  });
}
