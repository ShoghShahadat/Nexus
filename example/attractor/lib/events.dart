/// An event to notify systems of the current screen dimensions.
/// رویدادی برای اطلاع‌رسانی ابعاد فعلی صفحه به سیستم‌ها.
class ScreenResizeEvent {
  final double width;
  final double height;
  ScreenResizeEvent(this.width, this.height);
}

/// An event to signal that the game should be reset to its initial state.
/// رویدادی برای سیگنال دادن به منظور ریست کردن بازی به حالت اولیه.
class RestartGameEvent {}
