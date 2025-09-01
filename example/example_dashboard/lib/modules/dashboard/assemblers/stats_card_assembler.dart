import 'package:nexus/nexus.dart';
import 'package:example_dashboard/shared/components/tags.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

/// یک Assembler برای ایجاد موجودیت‌های مربوط به کارت‌های آمار.
class StatsCardAssembler extends EntityAssembler<void> {
  StatsCardAssembler(super.world, super.context);

  @override
  List<Entity> assemble() {
    final cardData = [
      {'title': 'Revenue', 'icon': 0xea4d, 'value': '\$0', 'trend': Trend.up},
      {'title': 'Users', 'icon': 0xe49a, 'value': '0', 'trend': Trend.down},
      {
        'title': 'Engagement',
        'icon': 0xf051d,
        'value': '0.0%',
        'trend': Trend.stable
      },
      {'title': 'Sales', 'icon': 0xf051b, 'value': '0', 'trend': Trend.up},
    ];

    final createdCards = <Entity>[];

    for (var data in cardData) {
      // --- CRITICAL FIX: Two-step entity creation and configuration. ---
      // 1. Create the entity and immediately add it to the world.
      // 2. Add components to the now-registered entity.
      // اصلاح حیاتی: ایجاد و پیکربندی موجودیت در دو مرحله.
      // ۱. موجودیت را ایجاد کرده و بلافاصله آن را به دنیا اضافه می‌کنیم.
      // ۲. کامپوننت‌ها را به موجودیت ثبت‌شده اضافه می‌کنیم.
      final cardEntity = Entity();
      world.addEntity(cardEntity);

      cardEntity.addComponents([
        TagsComponent({DashboardTags.statsCard}),
        StatsCardComponent(
          title: data['title'] as String,
          iconData: data['icon'] as int,
          value: data['value'] as String,
          trend: data['trend'] as Trend,
        )
      ]);
      createdCards.add(cardEntity);
    }
    return createdCards;
  }
}
