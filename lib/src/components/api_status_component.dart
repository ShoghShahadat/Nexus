import 'package:nexus/nexus.dart';

/// Enum representing the current status of an API request.
/// این enum وضعیت فعلی یک درخواست API را نشان می‌دهد.
enum ApiStatus {
  /// The request has not been initiated.
  /// درخواست هنوز آغاز نشده است.
  idle,

  /// The request is currently in progress.
  /// درخواست در حال انجام است.
  loading,

  /// The request completed successfully.
  /// درخواست با موفقیت انجام شد.
  success,

  /// The request failed.
  /// درخواست با شکست مواجه شد.
  error,
}

/// A serializable component that represents the UI-facing status of an API request.
/// یک کامپوننت سریالایزبل که وضعیت قابل نمایش یک درخواست API را نشان می‌دهد.
///
/// This component is managed by the `ApiSystem` and can be used by the rendering
/// layer to display loading indicators, error messages, or the final data.
/// این کامپوننت توسط `ApiSystem` مدیریت می‌شود و لایه رندرینگ می‌تواند از آن برای
/// نمایش نشانگرهای بارگذاری، پیام‌های خطا یا داده‌های نهایی استفاده کند.
class ApiStatusComponent extends Component with SerializableComponent {
  final ApiStatus status;
  final String? errorMessage;
  final int? statusCode;

  ApiStatusComponent({
    this.status = ApiStatus.idle,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiStatusComponent.fromJson(Map<String, dynamic> json) {
    return ApiStatusComponent(
      status: ApiStatus.values[json['status'] as int],
      errorMessage: json['errorMessage'] as String?,
      statusCode: json['statusCode'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'status': status.index,
        'errorMessage': errorMessage,
        'statusCode': statusCode,
      };

  @override
  List<Object?> get props => [status, errorMessage, statusCode];
}
