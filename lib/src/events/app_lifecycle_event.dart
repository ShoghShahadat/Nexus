/// An enum mirroring Flutter's AppLifecycleState to be safely used in the logic isolate.
/// یک enum مشابه AppLifecycleState فلاتر برای استفاده امن در isolate منطق.
enum AppLifecycleStatus {
  resumed,
  inactive,
  paused,
  detached,
  hidden,
}

/// An event fired from the UI thread to the logic isolate when the application's
/// lifecycle state changes.
/// رویدادی که هنگام تغییر وضعیت چرخه حیات برنامه، از ترد UI به isolate منطق ارسال می‌شود.
class AppLifecycleEvent {
  final AppLifecycleStatus status;

  AppLifecycleEvent(this.status);
}
