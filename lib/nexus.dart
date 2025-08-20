/// The main library for the Nexus framework.
library nexus;

// --- Core ---
export 'src/core/component.dart';
export 'src/core/entity.dart';
export 'src/core/event_bus.dart';
export 'src/core/nexus_module.dart';
export 'src/core/nexus_world.dart';
export 'src/core/system.dart';
export 'src/core/providers/entity_provider.dart';
export 'src/core/providers/system_provider.dart';
export 'src/core/assemblers/entity_assembler.dart';
export 'src/core/logic/logic_function.dart';
export 'src/core/utils/equatable_mixin.dart';

// --- Serialization ---
export 'src/core/serialization/serializable_component.dart';
export 'src/core/serialization/component_factory.dart';
export 'src/core/serialization/world_serializer.dart';
export 'src/core/render_packet.dart';

// --- Events ---
export 'src/events/shape_events.dart';
export 'src/events/input_events.dart';
export 'src/events/pointer_events.dart';

// --- Components ---
export 'src/components/animation_component.dart';
export 'src/components/animation_progress_component.dart';
export 'src/components/attractor_component.dart';
export 'src/components/bloc_component.dart';
export 'src/components/children_component.dart';
export 'src/components/clickable_component.dart';
export 'src/components/counter_state_component.dart';
export 'src/components/custom_widget_component.dart';
export 'src/components/lifecycle_component.dart';
export 'src/components/morphing_component.dart';
export 'src/components/particle_component.dart';
export 'src/components/position_component.dart';
export 'src/components/shape_path_component.dart';
export 'src/components/spawner_component.dart';
export 'src/components/tags_component.dart';
export 'src/components/velocity_component.dart';
export 'src/components/widget_component.dart';

// --- Systems ---
export 'src/systems/animation_system.dart';
export 'src/systems/attraction_system.dart';
export 'src/systems/bloc_system.dart';
export 'src/systems/flutter_rendering_system.dart';
export 'src/systems/input_system.dart';
export 'src/systems/lifecycle_system.dart';
export 'src/systems/morphing_system.dart';
export 'src/systems/particle_lifecycle_system.dart';
export 'src/systems/particle_spawning_system.dart';
export 'src/systems/physics_system.dart';
export 'src/systems/pointer_system.dart';
export 'src/systems/pulsing_warning_system.dart';
export 'src/systems/shape_selection_system.dart';

// --- Flutter Bridge ---
export 'src/flutter/entity_widget_builder.dart';
export 'src/flutter/nexus_widget.dart';
// *** FIX: Export all manager classes. ***
export 'src/flutter/nexus_manager.dart';
export 'src/flutter/nexus_isolate_manager.dart';
export 'src/flutter/nexus_single_thread_manager.dart';
export 'src/flutter/builder_tags.dart';
