/// The main library for the Nexus framework.
///
/// This file exports all the public-facing APIs of the Nexus package,
/// allowing users to import all core functionalities with a single line.
library nexus;

// --- Core ---
export 'src/core/component.dart';
export 'src/core/entity.dart';
export 'src/core/event_bus.dart';
export 'src/core/nexus_module.dart';
export 'src/core/nexus_world.dart';
export 'src/core/system.dart';

// --- Events ---
export 'src/events/shape_events.dart';

// --- Components ---
export 'src/components/animation_component.dart';
export 'src/components/bloc_component.dart';
export 'src/components/clickable_component.dart'; // Re-introduced
export 'src/components/counter_state_component.dart';
export 'src/components/lifecycle_component.dart';
export 'src/components/morphing_component.dart';
export 'src/components/position_component.dart';
export 'src/components/shape_path_component.dart';
export 'src/components/tags_component.dart';
export 'src/components/velocity_component.dart';
export 'src/components/widget_component.dart';

// --- Systems ---
export 'src/systems/animation_system.dart';
export 'src/systems/bloc_system.dart';
export 'src/systems/flutter_rendering_system.dart';
// InputSystem is removed
export 'src/systems/lifecycle_system.dart';
export 'src/systems/morphing_system.dart';
export 'src/systems/physics_system.dart';
export 'src/systems/pulsing_warning_system.dart';
export 'src/systems/shape_selection_system.dart';

// --- Flutter Bridge ---
export 'src/flutter/entity_widget_builder.dart';
export 'src/flutter/nexus_widget.dart';
