import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/dashboard_assembler.dart';
import 'package:example_dashboard/modules/dashboard/systems/stats_updater_system.dart';
import 'package:example_dashboard/services/mock_api_service.dart';

/// ماژول اصلی داشبورد که سیستم‌ها و Entityهای اولیه را تعریف و فراهم می‌کند.
class DashboardModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // FIX: Accessed GetIt instance via world.services instead of a non-existent module property.
    // اصلاح: دسترسی به نمونه GetIt از طریق world.services به جای یک پراپرتی ناموجود در ماژول انجام شد.
    if (!world.services.isRegistered<MockApiService>()) {
      world.services.registerSingleton(MockApiService());
    }
  }

  @override
  List<EntityProvider> get entityProviders => [
        // این provider مسئول ساخت Entityهای اولیه داشبورد است.
        DashboardEntityProvider(),
      ];

  @override
  List<SystemProvider> get systemProviders => [
        // این provider سیستم‌هایی که در این ماژول فعال هستند را فراهم می‌کند.
        DashboardSystemProvider(),
      ];
}

/// فراهم‌کننده سیستم‌های ماژول داشبورد.
class DashboardSystemProvider extends SystemProvider {
  @override
  List<System> get systems => [
        // این سیستم به صورت دوره‌ای آمار کارت‌ها را به‌روزرسانی می‌کند.
        StatsUpdaterSystem(),
      ];
}

/// فراهم‌کننده Entityهای ماژول داشبورد.
class DashboardEntityProvider extends EntityProvider {
  @override
  void createEntities(NexusWorld world) {
    // از DashboardAssembler برای ساخت ساختار اولیه Entityها استفاده می‌کنیم.
    DashboardAssembler(world).assemble();
  }
}
