import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/screen_info_component.dart';

/// A logic-only component that defines how an entity should adapt its layout
/// and components based on screen size and orientation.
///
/// Note: This component is NOT serializable because it holds Archetype objects,
/// which contain functions and other non-serializable components. It should be
/// defined and managed within the logic isolate.
class ResponsiveComponent extends Component {
  /// A map of screen width breakpoints to the archetypes that should be applied.
  /// The keys are the maximum width for which the archetype is valid.
  /// The map should be sorted by key in ascending order.
  ///
  /// Example:
  /// {
  ///   600: mobileLayoutArchetype,  // for screens < 600px wide
  ///   1200: tabletLayoutArchetype, // for screens >= 600px and < 1200px wide
  ///   double.infinity: desktopLayoutArchetype // for screens >= 1200px wide
  /// }
  final Map<double, Archetype> breakpoints;

  /// An optional map of archetypes to be applied for specific screen orientations.
  final Map<ScreenOrientation, Archetype>? orientationArchetypes;

  /// The last archetype that was applied by the ResponsivenessSystem.
  /// This is used internally to avoid reapplying the same archetype and to
  /// correctly remove the old one.
  Archetype? lastAppliedArchetype;

  ResponsiveComponent({
    required this.breakpoints,
    this.orientationArchetypes,
    this.lastAppliedArchetype,
  });

  @override
  List<Object?> get props =>
      [breakpoints, orientationArchetypes, lastAppliedArchetype];
}
