import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/systems/stats_updater_system.dart';

/// ارائه‌دهنده سیستم‌های ماژول داشبورد.
class DashboardSystemProvider implements SystemProvider {
  @override
  List<System> get systems => [
        // --- NEW: Added the system for automatic updates ---
        // --- جدید: سیستم به‌روزرسانی خودکار اضافه شد ---
        StatsUpdaterSystem(),
      ];
}
