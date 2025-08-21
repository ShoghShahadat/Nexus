/// رویدادی که برای تغییر تم فعال برنامه ارسال می‌شود.
///
/// ThemingSystem به این رویداد گوش می‌دهد تا ظاهر تمام موجودیت‌های استایل‌پذیر را به‌روز کند.
class ThemeChangedEvent {
  /// شناسه تم جدیدی که باید فعال شود.
  final String newThemeId;

  ThemeChangedEvent(this.newThemeId);
}
