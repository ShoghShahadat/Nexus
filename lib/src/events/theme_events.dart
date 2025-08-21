/// An event fired to change the active theme of the application.
///
/// The `ThemingSystem` listens for this event to update the appearance
/// of all styleable entities.
class ThemeChangedEvent {
  /// The ID of the new theme to be activated.
  final String newThemeId;

  ThemeChangedEvent(this.newThemeId);
}
