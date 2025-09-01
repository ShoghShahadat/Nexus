import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/systems/stats_updater_system.dart';
import 'package:example_dashboard/modules/dashboard/systems/user_activity_streaming_system.dart';

class DashboardSystemProvider implements SystemProvider {
  @override
  List<System> get systems => [
        StatsCardUpdaterSystem(),
        UserActivityStreamingSystem(), // Add the new system
      ];
}
