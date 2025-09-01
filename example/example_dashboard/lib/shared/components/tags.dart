/// کلاس متمرکز برای تعریف تگ‌های مورد استفاده در ماژول داشبورد.
/// استفاده از این کلاس به جای رشته‌های مستقیم، از خطا جلوگیری کرده و خوانایی را افزایش می‌دهد.
class DashboardTags {
  // FIX: Renamed 'dashboard_root' to 'root' to match the tag assigned by NexusWorld.
  // This ensures consistency and allows the assembler to find the correct root entity.
  // اصلاح: نام 'dashboard_root' به 'root' برای تطابق با تگ تخصیص داده شده توسط NexusWorld تغییر کرد.
  // این کار هماهنگی را تضمین کرده و به assembler اجازه می‌دهد Entity ریشه صحیح را پیدا کند.
  static const String root = 'root';

  static const String header = 'dashboard_header';
  static const String statsCardContainer = 'stats_card_container';
  static const String statsCard = 'stats_card';
}
