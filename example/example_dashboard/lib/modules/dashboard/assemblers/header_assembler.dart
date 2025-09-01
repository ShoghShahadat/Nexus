import 'package:nexus/nexus.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// یک Assembler برای ایجاد موجودیت مربوط به هدر داشبورد.
class HeaderAssembler extends EntityAssembler<void> {
  HeaderAssembler(super.world, super.context);

  @override
  List<Entity> assemble() {
    // --- CRITICAL FIX: Two-step entity creation and configuration. ---
    // 1. Create the entity and immediately add it to the world.
    //    This correctly initializes the `entity.world` property.
    // 2. Add components to the now-registered entity.
    // اصلاح حیاتی: ایجاد و پیکربندی موجودیت در دو مرحله.
    // ۱. موجودیت را ایجاد کرده و بلافاصله آن را به دنیا اضافه می‌کنیم.
    //    این کار پراپرتی `entity.world` را به درستی مقداردهی اولیه می‌کند.
    // ۲. کامپوننت‌ها را به موجودیت ثبت‌شده اضافه می‌کنیم.
    final header = Entity();
    world.addEntity(header);

    header.addComponents([
      TagsComponent({DashboardTags.header}),
      CustomWidgetComponent(
        widgetType: 'header',
        properties: {
          'title': 'Dashboard Overview',
          'subtitle': 'Welcome back, User!',
        },
      )
    ]);

    return [header];
  }
}
