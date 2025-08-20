import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/api_request_component.dart';
import 'package:nexus/src/components/api_status_component.dart';
import 'package:nexus/src/services/network/i_network_service.dart';

/// The central system for handling all network requests within the Nexus world.
/// سیستم مرکزی برای مدیریت تمام درخواست‌های شبکه در دنیای Nexus.
///
/// It looks for entities with an `ApiRequestComponent`, performs the request
/// using the registered `INetworkService`, and updates the entity's state
/// with an `ApiStatusComponent` and the parsed data components.
/// این سیستم به دنبال موجودیت‌های دارای `ApiRequestComponent` می‌گردد، درخواست را
/// با استفاده از `INetworkService` ثبت‌شده انجام می‌دهد و وضعیت موجودیت را با
/// `ApiStatusComponent` و کامپوننت‌های داده‌ای پارس‌شده به‌روزرسانی می‌کند.
class ApiSystem extends System {
  late final INetworkService _networkService;
  bool _isServiceInitialized = false;

  @override
  Future<void> init() async {
    // Lazily fetch the network service from the service locator.
    // This ensures the developer has registered it before the world starts.
    // سرویس شبکه را از سرویس لوکیتور دریافت می‌کند.
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
  bool matches(Entity entity) {
    // This system only acts on entities that have just received an ApiRequestComponent.
    // این سیستم فقط روی موجودیت‌هایی که به تازگی ApiRequestComponent دریافت کرده‌اند عمل می‌کند.
    return entity.has<ApiRequestComponent>();
  }

  @override
  void update(Entity entity, double dt) async {
    if (!_isServiceInitialized) return;

    final requestComponent = entity.get<ApiRequestComponent>()!;

    // Immediately remove the request component to prevent it from being processed again.
    // کامپوننت درخواست را فوراً حذف می‌کنیم تا دوباره پردازش نشود.
    entity.remove<ApiRequestComponent>();

    // Set the initial state to loading.
    // وضعیت اولیه را روی "در حال بارگذاری" تنظیم می‌کنیم.
    entity.add(ApiStatusComponent(status: ApiStatus.loading));

    try {
      final responseJson = await _networkService.request(
        requestComponent.url,
        method: requestComponent.method,
        body: requestComponent.body,
        headers: requestComponent.headers,
      );

      // Parse the JSON response into data components.
      // پاسخ JSON را به کامپوننت‌های داده‌ای پارس می‌کنیم.
      final dataComponents = requestComponent.onParse(responseJson);

      // Add all the new data components to the entity.
      // تمام کامپوننت‌های داده‌ای جدید را به موجودیت اضافه می‌کنیم.
      for (final component in dataComponents) {
        entity.add(component);
      }

      // Update the status to success.
      // وضعیت را به "موفق" تغییر می‌دهیم.
      entity.add(ApiStatusComponent(status: ApiStatus.success));

      // Fire the success event if provided.
      // رویداد موفقیت را در صورت وجود، منتشر می‌کنیم.
      if (requestComponent.onSuccessEvent != null) {
        world.eventBus.fire(requestComponent.onSuccessEvent);
      }
    } catch (e, stacktrace) {
      print('[ApiSystem] Network request failed for ${requestComponent.url}');
      print('Error: $e');
      print('Stacktrace: $stacktrace');

      // Update the status to error.
      // وضعیت را به "خطا" تغییر می‌دهیم.
      entity.add(ApiStatusComponent(
        status: ApiStatus.error,
        errorMessage: e.toString(),
        // You might want to parse a proper status code from a specific exception type.
        // ممکن است بخواهید کد وضعیت را از یک نوع استثنای خاص پارس کنید.
        statusCode: null,
      ));

      // Fire the error event if provided.
      // رویداد خطا را در صورت وجود، منتشر می‌کنیم.
      if (requestComponent.onErrorEvent != null) {
        world.eventBus.fire(requestComponent.onErrorEvent);
      }
    }
  }
}
