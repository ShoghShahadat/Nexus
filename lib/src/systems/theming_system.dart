import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/decoration_components.dart';
import 'package:nexus/src/events/theme_events.dart';
import 'package:nexus/src/components/styleable_component.dart';
import 'package:nexus/src/components/theme_component.dart';

// A mock service for providing theme data.
// In a real application, this data could be loaded from a JSON file or an API.
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

/// A system responsible for managing and applying themes across the application.
///
/// This system listens for `ThemeChangedEvent` and, in response, updates the
/// appearance of all entities that have a `StyleableComponent`.
class ThemingSystem extends System {
  late final ThemeProviderService _themeProvider;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Register and retrieve the theme provider service.
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

    // 1. Update the central ThemeComponent.
    final newThemeProperties =
        _themeProvider.getThemeProperties(event.newThemeId);
    rootEntity.add(
        ThemeComponent(id: event.newThemeId, properties: newThemeProperties));

    // 2. Find and update all styleable entities.
    final styleableEntities =
        world.entities.values.where((e) => e.has<StyleableComponent>());

    for (final entity in styleableEntities) {
      final styleable = entity.get<StyleableComponent>()!;
      final currentDecoration =
          entity.get<DecorationComponent>() ?? DecorationComponent();

      // Create a new decoration based on the bindings and the new theme.
      // For simplicity, we're only handling backgroundColor here.
      final boundColorKey = styleable.styleBindings['backgroundColor'];
      if (boundColorKey != null) {
        final newColorValue = newThemeProperties[boundColorKey] as int?;
        if (newColorValue != null) {
          entity.add(DecorationComponent(
            color: SolidColor(newColorValue),
            boxShadow: currentDecoration.boxShadow, // Preserve other properties
          ));
        }
      }
      // Similar logic can be added for other properties like shadowColor, borderColor, etc.
    }
  }

  @override
  bool matches(Entity entity) => false; // This system is purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
