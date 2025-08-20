import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_module/entities/counter_entities.dart';
import 'package:nexus_example/counter_module/systems/counter_systems.dart';

/// The main assembler for the counter feature.
///
/// This class adheres to the Single Responsibility Principle by delegating
/// all implementation details to specialized providers. Its only job is to
/// compose the feature by defining which providers are part of it.
class CounterModule extends NexusModule {
  @override
  List<SystemProvider> get systemProviders => [
        CounterSystemProvider(),
      ];

  @override
  List<EntityProvider> get entityProviders => [
        CounterEntityProvider(),
      ];
}
