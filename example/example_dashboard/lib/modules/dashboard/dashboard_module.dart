import 'package:nexus/nexus.dart';
import 'package:example_dashboard/services/mock_api_service.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/header_assembler.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/stats_card_assembler.dart';
import 'package:example_dashboard/modules/dashboard/dashboard_system_provider.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/charts_assembler.dart';

/// ماژول اصلی داشبورد که تمام سیستم‌ها و موجودیت‌های مربوطه را مدیریت می‌کند.
class DashboardModule extends NexusModule {
  @override
  List<SystemProvider> get systemProviders => [DashboardSystemProvider()];

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  void onLoad(NexusWorld world) {
    // ثبت سرویس شبیه‌ساز API در GetIt
    world.services.registerSingleton(MockApiService());

    // --- NEW: Assemble all dashboard entities ---
    // --- جدید: تمام موجودیت‌های داشبورد را مونتاژ می‌کند ---
    HeaderAssembler(world, null).assemble();
    StatsCardAssembler(world, null).assemble();
    ChartsAssembler(world, null).assemble();
  }
}
