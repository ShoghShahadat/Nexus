import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/assemblers/stats_card_assembler.dart';
import 'package:example_dashboard/modules/dashboard/components/header_component.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// این کلاس مسئولیت ساخت و پیکربندی Entityهای اصلی ساختار داشبورد را دارد.
/// REFACTORED: Now finds the existing root entity and adds the dashboard
/// structure as children, instead of creating a redundant root entity.
/// بازآفرینی: اکنون به جای ساخت یک Entity ریشه اضافی، Entity ریشه موجود را
/// پیدا کرده و ساختار داشبورد را به عنوان فرزندان آن اضافه می‌کند.
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

    // ۴. پیدا کردن Entity ریشه (که توسط NexusWorld با ID=0 ساخته شده)
    // و اضافه کردن ساختار داشبورد به عنوان فرزندان آن.
    final rootEntity = world.entities[0]!;
    rootEntity
        .add(ChildrenComponent([headerEntity.id, cardContainerEntity.id]));
  }
}
