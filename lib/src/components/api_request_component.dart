import 'package:nexus/nexus.dart';
import 'package:nexus/src/services/network/http_method.dart';

/// A logic-only component that triggers a network request.
/// یک کامپوننت فقط-منطقی که یک درخواست شبکه را آغاز می‌کند.
///
/// This component is NOT serializable as it contains a function (`onParse`).
/// It should be added to an entity to instruct the `ApiSystem` to perform a
/// network call.
/// این کامپوننت به دلیل داشتن تابع، سریالایزبل نیست. باید به یک موجودیت اضافه شود
/// تا به `ApiSystem` دستور دهد یک فراخوانی شبکه انجام دهد.
class ApiRequestComponent extends Component {
  final String url;
  final HttpMethod method;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;

  /// A mandatory parser function that converts the JSON response into a list
  /// of serializable components. This enforces a data-driven, component-based
  /// approach to handling server data.
  /// یک تابع اجباری که پاسخ JSON را به لیستی از کامپوننت‌های سریالایزبل تبدیل می‌کند.
  /// این رویکرد، یک معماری داده-محور و مبتنی بر کامپوننت را برای داده‌های سرور الزام می‌کند.
  final List<Component> Function(Map<String, dynamic> json) onParse;

  /// An optional event to be fired on the event bus upon successful completion.
  /// The event can carry the parsed data components if needed.
  /// یک رویداد اختیاری که پس از موفقیت در event bus منتشر می‌شود.
  final dynamic onSuccessEvent;

  /// An optional event to be fired on the event bus if the request fails.
  /// یک رویداد اختیاری که در صورت شکست درخواست در event bus منتشر می‌شود.
  final dynamic onErrorEvent;

  ApiRequestComponent({
    required this.url,
    required this.onParse,
    this.method = HttpMethod.get,
    this.body,
    this.headers,
    this.onSuccessEvent,
    this.onErrorEvent,
  });

  // This component contains functions, so it uses reference equality.
  // این کامپوننت به دلیل داشتن تابع، از برابری بر اساس رفرنس استفاده می‌کند.
  @override
  List<Object?> get props => [
        url,
        method,
        body,
        headers,
        onParse,
        onSuccessEvent,
        onErrorEvent,
      ];
}
