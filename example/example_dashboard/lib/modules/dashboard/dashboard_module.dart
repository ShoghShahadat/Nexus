import 'package:nexus/nexus.dart';
import 'package:example_dashboard/services/mock_api_service.dart';
import 'package:example_dashboard/services/mock_web_socket_service.dart';

// Assemblers
import 'assemblers/charts_assembler.dart';
import 'assemblers/header_assembler.dart';
import 'assemblers/stats_card_assembler.dart';

// Systems
import 'systems/stats_card_updater_system.dart';

/// ماژول اصلی داشبورد که تمام سیستم‌ها و موجودیت‌های مربوطه را مدیریت می‌کند.
class DashboardModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // ثبت سرویس‌های شبیه‌سازی شده
    if (!world.services.isRegistered<MockApiService>()) {
      world.services.registerSingleton<MockApiService>(MockApiService());
    }
    if (!world.services.isRegistered<IWebSocketService>()) {
      world.services
          .registerSingleton<IWebSocketService>(MockWebSocketService());
    }
  }

  @override
  List<EntityProvider> get entityProviders => [
        DashboardEntityProvider(),
      ];

  @override
  List<SystemProvider> get systemProviders => [
        DashboardSystemProvider(),
      ];
}

/// فراهم‌کننده سیستم‌های مورد نیاز برای ماژول داشبورد.
class DashboardSystemProvider implements SystemProvider {
  @override
  List<System> get systems => [
        // FIX: Corrected the system class name.
        // اصلاح: نام کلاس سیستم تصحیح شد.
        StatsCardUpdaterSystem(),
        // سیستم‌های اصلی Nexus
        ApiSystem(),
        WebSocketSystem(),
        TimerSystem(),
      ];
}

/// فراهم‌کننده موجودیت‌های داشبورد با استفاده از Assemblerها.
class DashboardEntityProvider implements EntityProvider {
  @override
  void createEntities(NexusWorld world) {
    final rootId = world.rootEntity.id;

    // اسمبلرها را با کانتکست صحیح (شناسه ریشه) فراخوانی می‌کنیم.
    final headerEntities = HeaderAssembler(world, rootId).assemble();
    final statsCardEntities = StatsCardAssembler(world, rootId).assemble();
    final chartEntities = ChartsAssembler(world, rootId).assemble();

    // تمام موجودیت‌های ایجاد شده در سطح بالا را به عنوان فرزندان ریشه اضافه می‌کنیم.
    // این کار به جای نگاشت (map) کردن، مستقیماً تمام موجودیت‌های اصلی را به children اضافه می‌کند.
    final topLevelEntities = [
      ...headerEntities,
      ...statsCardEntities,
      ...chartEntities
    ];

    // فقط موجودیت‌هایی را اضافه می‌کنیم که والد ندارند (فرزندان مستقیم ریشه هستند).
    final rootChildrenIds = topLevelEntities
        .where((e) => e.get<ParentComponent>()?.parentId == rootId)
        .map((e) => e.id)
        .toList();

    world.rootEntity.add(ChildrenComponent(rootChildrenIds));
  }
}
