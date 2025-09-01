import 'package:nexus/nexus.dart';
import 'package:example_dashboard/services/mock_api_service.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/header_assembler.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/stats_card_assembler.dart';
import 'package:example_dashboard/modules/dashboard/dashboard_system_provider.dart';

/// ماژول اصلی داشبورد که تمام سیستم‌ها و موجودیت‌های مربوط به این بخش را مدیریت می‌کند.
class DashboardModule extends NexusModule {
  @override
  // This module now creates its entities directly in the onLoad method.
  // این ماژول اکنون موجودیت‌های خود را مستقیماً در متد onLoad ایجاد می‌کند.
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        DashboardSystemProvider(),
      ];

  @override
  void onLoad(NexusWorld world) {
    // Register the MockApiService as a singleton if it's not already there.
    // سرویس MockApiService را به عنوان سینگلتون ثبت می‌کنیم اگر قبلا ثبت نشده باشد.
    if (!world.services.isRegistered<MockApiService>()) {
      world.services.registerSingleton(MockApiService());
    }

    // --- CRITICAL FIX: The entire assembly logic is moved here. ---
    // This ensures that we have access to the `world` object to correctly
    // register entities before configuring them.
    // اصلاح حیاتی: تمام منطق assembly به اینجا منتقل شد.
    // این کار تضمین می‌کند که ما به آبجکت `world` برای ثبت صحیح موجودیت‌ها
    // قبل از پیکربندی آنها دسترسی داریم.

    final headerAssembler = HeaderAssembler(world, null);
    final statsCardAssembler = StatsCardAssembler(world, null);

    // Assemble methods now return the created entities.
    // متدهای assemble اکنون موجودیت‌های ایجاد شده را برمی‌گردانند.
    final header = headerAssembler.assemble().first;
    final statsCards = statsCardAssembler.assemble();

    // The assemblers themselves now handle adding entities to the world,
    // so we only need to set up the hierarchy here.
    // خود assemblerها اکنون افزودن موجودیت‌ها به دنیا را مدیریت می‌کنند،
    // بنابراین ما فقط باید سلسله‌مراتب را اینجا تنظیم کنیم.
    final root = world.rootEntity;
    root.add(ChildrenComponent([
      header.id,
      ...statsCards.map((e) => e.id),
    ]));
  }
}
