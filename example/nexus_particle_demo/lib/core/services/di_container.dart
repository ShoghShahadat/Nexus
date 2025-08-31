import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/component_factory.dart';

/// Global service locator instance.
/// نمونه سراسری سرویس لوکیتور.
final sl = GetIt.instance;

/// Sets up the dependency injection container.
/// کانتینر تزریق وابستگی را راه‌اندازی می‌کند.
void setupDI() {
  // *** CRITICAL FIX: Register all core serializable components ***
  // This must be called on the main UI thread so that the FlutterRenderingSystem
  // knows how to deserialize the component data it receives in RenderPackets
  // from the logic isolate.
  //
  // *** اصلاح حیاتی: ثبت تمام کامپوننت‌های سریالایزبل هسته ***
  // این تابع باید در ترد اصلی UI فراخوانی شود تا FlutterRenderingSystem
  // بداند چگونه داده‌های کامپوننتی را که در RenderPacketها از ایزولیت منطق
  // دریافت می‌کند، دی‌سریالایز کند.
  registerCoreComponents();

  // Example of registering a service:
  // sl.registerLazySingleton<INetworkService>(() => DioNetworkService());
}
