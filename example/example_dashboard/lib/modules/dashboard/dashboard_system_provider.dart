import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/systems/stats_updater_system.dart';

/// یک فراهم‌کننده (Provider) برای تمام سیستم‌های مربوط به ماژول داشبورد.
class DashboardSystemProvider implements SystemProvider {
  @override
  List<System> get systems => [
        // سیستمی که باعث خطا می‌شد، اکنون به درستی کار خواهد کرد.
        StatsUpdaterSystem(),
      ];
}
