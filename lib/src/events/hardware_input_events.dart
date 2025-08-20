/// Defines the types of hardware buttons that the framework can handle.
/// انواع دکمه‌های سخت‌افزاری که فریم‌ورک می‌تواند مدیریت کند را تعریف می‌کند.
enum HardwareButtonType {
  /// The physical back button on Android, or the equivalent navigation pop gesture.
  /// دکمه بازگشت فیزیکی در اندروید، یا ژست حرکتی معادل آن.
  back,

  /// The volume up button.
  /// دکمه افزایش صدا.
  volumeUp,

  /// The volume down button.
  /// دکمه کاهش صدا.
  volumeDown,
}

/// An event fired from the UI thread to the logic isolate when a physical
/// hardware button is pressed.
/// رویدادی که هنگام فشرده شدن یک دکمه سخت‌افزاری فیزیکی، از ترد UI به
/// isolate منطق ارسال می‌شود.
class HardwareButtonEvent {
  final HardwareButtonType type;

  HardwareButtonEvent(this.type);
}
