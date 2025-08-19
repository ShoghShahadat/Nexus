/// The main library for the Nexus framework.
///
/// This file exports all the public-facing APIs of the Nexus package,
/// allowing users to import all core functionalities with a single line.
library nexus;

// --- Core ---
export 'src/core/component.dart';
export 'src/core/entity.dart';
export 'src/core/nexus_world.dart';
export 'src/core/system.dart';

// --- Components ---
export 'src/components/bloc_component.dart';
export 'src/components/clickable_component.dart';
export 'src/components/counter_state_component.dart';
export 'src/components/lifecycle_component.dart'; // Exporting the new component
export 'src/components/position_component.dart';
export 'src/components/widget_component.dart';

// --- Systems ---
export 'src/systems/bloc_system.dart';
export 'src/systems/flutter_rendering_system.dart';
export 'src/systems/input_system.dart';
export 'src/systems/lifecycle_system.dart'; // Exporting the new system

// --- Flutter Bridge ---
export 'src/flutter/entity_widget_builder.dart';
export 'src/flutter/nexus_widget.dart';
