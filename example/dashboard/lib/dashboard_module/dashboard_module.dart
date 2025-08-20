import 'package:nexus/nexus.dart';
import 'package:nexus_example/dashboard_module/data/mock_data_provider.dart';
import 'package:nexus_example/dashboard_module/entities/dashboard_entities.dart';
import 'package:nexus_example/dashboard_module/systems/dashboard_systems.dart';

/// The main module for the dashboard feature.
///
/// This class acts as an aggregator, bringing together all the providers
/// (SystemProviders, EntityProviders) that define the feature's logic and data.
/// It also handles the registration of any services required by the module.
class DashboardModule extends NexusModule {
  @override
  List<SystemProvider> get systemProviders => [
        DashboardSystemProvider(),
      ];

  @override
  List<EntityProvider> get entityProviders => [
        DashboardEntityProvider(),
      ];

  /// This lifecycle method is called when the module is loaded into the world.
  /// It's the perfect place to register services needed by this module.
  @override
  void onLoad(NexusWorld world) {
    // Register the MockDataProvider as a singleton service.
    // This allows any system or entity assembler within this world to access it.
    world.services.registerSingleton(MockDataProvider());
  }
}
