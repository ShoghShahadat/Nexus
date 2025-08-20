import 'package:nexus/src/services/network/http_method.dart';

/// An abstract interface for a network service.
/// این یک اینترفیس انتزاعی برای سرویس شبکه است.
///
/// This contract decouples the ApiSystem from the actual network request
/// implementation (e.g., dio, http). The developer must provide a concrete
/// implementation of this class and register it with the service locator (GetIt).
/// این قرارداد، سیستم ApiSystem را از پیاده‌سازی واقعی درخواست شبکه جدا می‌کند.
/// توسعه‌دهنده باید یک پیاده‌سازی مشخص از این کلاس را ارائه داده و آن را در
/// سرویس لوکیتور (GetIt) ثبت کند.
abstract class INetworkService {
  /// Performs a network request.
  /// یک درخواست شبکه را انجام می‌دهد.
  ///
  /// Must return a Future that resolves to a `Map<String, dynamic>` which
  /// represents the JSON response body. If the request fails, it should
  /// throw an exception that the ApiSystem can catch.
  /// باید یک Future برگرداند که به یک `Map<String, dynamic>` (بدنه پاسخ JSON)
  /// حل می‌شود. اگر درخواست با شکست مواجه شود، باید یک استثنا پرتاب کند.
  Future<Map<String, dynamic>> request(
    String url, {
    required HttpMethod method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  });
}
