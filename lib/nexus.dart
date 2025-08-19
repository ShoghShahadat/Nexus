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

// --- Systems ---
export 'src/systems/bloc_system.dart';

// --- Flutter Bridge ---
export 'src/flutter/nexus_widget.dart';
