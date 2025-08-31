import 'package:nexus/nexus.dart';

/// The central system for handling all network requests within the Nexus world.
///
/// --- RE-ARCHITECTED as a ReactiveSystem ---
/// This is a perfect use case for a reactive system. It only needs to run
/// when an `ApiRequestComponent` is ADDED to an entity.
class ApiSystem extends ReactiveSystem {
  late final INetworkService _networkService;
  bool _isServiceInitialized = false;

  @override
  Set<Type> get subscribedComponentTypes => {ApiRequestComponent};

  @override
  Future<void> init() async {
    try {
      _networkService = services.get<INetworkService>();
      _isServiceInitialized = true;
    } catch (e) {
      print(
          '[ApiSystem] FATAL ERROR: INetworkService not found in GetIt. Please register your network service implementation before starting the NexusWorld.');
      _isServiceInitialized = false;
    }
  }

  @override
  void onComponentChanged(
      Entity entity, Component? oldComponent, Component newComponent) async {
    if (!_isServiceInitialized || newComponent is! ApiRequestComponent) return;

    final requestComponent = newComponent;

    // Immediately remove the request component to prevent it from being processed again.
    Future.microtask(() => entity.remove<ApiRequestComponent>());

    // Set the initial state to loading.
    entity.add(ApiStatusComponent(status: ApiStatus.loading));

    try {
      final responseJson = await _networkService.request(
        requestComponent.url,
        method: requestComponent.method,
        body: requestComponent.body,
        headers: requestComponent.headers,
      );

      final dataComponents = requestComponent.onParse(responseJson);
      entity.addComponents(dataComponents);
      entity.add(ApiStatusComponent(status: ApiStatus.success));

      if (requestComponent.onSuccessEvent != null) {
        world.eventBus.fire(requestComponent.onSuccessEvent);
      }
    } catch (e, stacktrace) {
      print('[ApiSystem] Network request failed for ${requestComponent.url}');
      print('Error: $e');
      print('Stacktrace: $stacktrace');

      entity.add(ApiStatusComponent(
        status: ApiStatus.error,
        errorMessage: e.toString(),
        statusCode: null,
      ));

      if (requestComponent.onErrorEvent != null) {
        world.eventBus.fire(requestComponent.onErrorEvent);
      }
    }
  }

  @override
  void onComponentRemoved(Entity entity, Component removedComponent) {
    // No logic needed here.
  }
}
