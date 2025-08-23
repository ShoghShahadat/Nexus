import 'package:nexus/nexus.dart';
import 'components/attractor_component.dart' hide AttractorComponent;
import 'components/debug_info_component.dart';
import 'components/health_orb_component.dart';
import 'components/meteor_component.dart';
import 'components/network_components.dart';
import 'components/particle_render_data_component.dart';
import 'components/score_component.dart';

void registerAllComponents() {
  final customJsonComponents = <String, ComponentFactory>{
    'DebugInfoComponent': (json) => DebugInfoComponent.fromJson(json),
    'MeteorComponent': (json) => MeteorComponent.fromJson(json),
    'HealthOrbComponent': (json) => HealthOrbComponent.fromJson(json),
    'ScoreComponent': (json) => ScoreComponent.fromJson(json),
    'AttractorComponent': (json) => AttractorComponent.fromJson(json),
    'ParticleRenderDataComponent': (json) =>
        ParticleRenderDataComponent.fromJson(json),
  };
  ComponentFactoryRegistry.I.registerAll(customJsonComponents);

  final factory = BinaryComponentFactory.I;
  factory.register(1, () => PositionComponent());
  factory.register(2, () => PlayerComponent());
  factory.register(3, () => HealthComponent());
  factory.register(4, () => VelocityComponent());
  factory.register(5, () => TagsComponent());
  factory.register(11, () => ScoreComponent());
}
