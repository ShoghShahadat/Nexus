import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/theme_events.dart';
import 'package:nexus/src/components/styleable_component.dart';
import 'package:nexus/src/components/theme_component.dart';

// فرض می‌کنیم یک سرویس برای فراهم کردن داده‌های تم داریم.
// در یک اپلیکیشن واقعی، این داده‌ها می‌توانند از یک فایل JSON یا یک API خوانده شوند.
class ThemeProviderService {
  final Map<String, Map<String, dynamic>> _themes = {
    'light': {
      'primaryColor': 0xFF6200EE,
      'backgroundColor': 0xFFFFFFFF,
      'textColor': 0xFF000000,
      'shadowColor': 0x44000000,
    },
    'dark': {
      'primaryColor': 0xFFBB86FC,
      'backgroundColor': 0xFF121212,
      'textColor': 0xFFFFFFFF,
      'shadowColor': 0x44FFFFFF,
    },
  };

  Map<String, dynamic> getThemeProperties(String themeId) {
    return _themes[themeId] ?? _themes['light']!;
  }
}

/// سیستمی که مسئولیت مدیریت و اعمال تم‌ها در سراسر برنامه را بر عهده دارد.
///
/// این سیستم به رویداد ThemeChangedEvent گوش می‌دهد و بر اساس آن، ظاهر
/// تمام موجودیت‌های دارای StyleableComponent را به‌روزرسانی می‌کند.
class ThemingSystem extends System {
  late final ThemeProviderService _themeProvider;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // ثبت و دریافت سرویس فراهم‌کننده تم
    if (!services.isRegistered<ThemeProviderService>()) {
      services.registerSingleton(ThemeProviderService());
    }
    _themeProvider = services.get<ThemeProviderService>();

    world.eventBus.on<ThemeChangedEvent>(_onThemeChanged);
  }

  void _onThemeChanged(ThemeChangedEvent event) {
    final rootEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('root') ?? false);

    if (rootEntity == null) return;

    // ۱. به‌روزرسانی ThemeComponent مرکزی
    final newThemeProperties =
        _themeProvider.getThemeProperties(event.newThemeId);
    rootEntity.add(
        ThemeComponent(id: event.newThemeId, properties: newThemeProperties));

    // ۲. پیدا کردن و به‌روزرسانی تمام موجودیت‌های استایل‌پذیر
    final styleableEntities =
        world.entities.values.where((e) => e.has<StyleableComponent>());

    for (final entity in styleableEntities) {
      final styleable = entity.get<StyleableComponent>()!;
      final currentDecoration =
          entity.get<DecorationComponent>() ?? DecorationComponent();

      // یک دکوراسیشن جدید بر اساس اتصالات و تم جدید می‌سازیم
      // در اینجا برای سادگی فقط رنگ پس‌زمینه را در نظر می‌گیریم
      final boundColorKey = styleable.styleBindings['backgroundColor'];
      if (boundColorKey != null) {
        final newColorValue = newThemeProperties[boundColorKey] as int?;
        if (newColorValue != null) {
          entity.add(DecorationComponent(
            color: SolidColor(newColorValue),
            boxShadow: currentDecoration.boxShadow, // حفظ سایر ویژگی‌ها
          ));
        }
      }
      // منطق مشابهی برای سایر ویژگی‌ها مانند shadowColor, borderColor و ... می‌تواند اضافه شود
    }
  }

  @override
  bool matches(Entity entity) => false; // سیستم کاملاً رویداد-محور است

  @override
  void update(Entity entity, double dt) {}
}
