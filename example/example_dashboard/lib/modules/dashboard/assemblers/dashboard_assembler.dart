import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/stats_card_assembler.dart';
import 'package:example_dashboard/modules/dashboard/components/header_component.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// این کلاس مسئولیت ساخت و پیکربندی Entityهای اصلی ساختار داشبورد را دارد.
/// REFACTORED: Now creates a single root entity to define the page structure.
/// بازآفرینی: اکنون یک Entity ریشه واحد برای تعریف ساختار صفحه ایجاد می‌کند.
class DashboardAssembler {
  final NexusWorld world;

  DashboardAssembler(this.world);

  /// ساختار اصلی Entityها را ایجاد و به world اضافه می‌کند.
  void assemble() {
    // ۱. ساخت Entity برای هدر
    final headerEntity = Entity()
      ..add(HeaderComponent(
        title: 'Dashboard',
        userName: 'Shahrokh',
      ))
      ..add(TagsComponent({DashboardTags.header}));
    world.addEntity(headerEntity);

    // ۲. ساخت Entityهای کارت‌های آمار
    final statsCards = StatsCardAssembler(world).assemble();
    for (var card in statsCards) {
      world.addEntity(card);
    }

    // ۳. ساخت Entity نگهدارنده کارت‌ها
    final cardContainerEntity = Entity()
      ..add(ChildrenComponent(statsCards.map((e) => e.id).toList()))
      ..add(TagsComponent({DashboardTags.statsCardContainer}));
    world.addEntity(cardContainerEntity);

    // ۴. ساخت Entity ریشه که ساختار کلی صفحه را مشخص می‌کند.
    final rootEntity = Entity()
      ..add(TagsComponent({DashboardTags.root}))
      ..add(ChildrenComponent([headerEntity.id, cardContainerEntity.id]));
    world.addEntity(rootEntity);
  }
}
