import 'package:nexus/nexus.dart';

/// یک کامپوننت داده-محور که وضعیت و مقادیر تم فعلی برنامه را نگهداری می‌کند.
///
/// این کامپوننت معمولاً روی یک موجودیت مرکزی (مانند 'root') قرار می‌گیرد
/// و توسط ThemingSystem برای اعمال استایل‌ها به موجودیت‌های دیگر استفاده می‌شود.
class ThemeComponent extends Component with SerializableComponent {
  /// شناسه یکتای تم فعلی (مثلاً 'dark_mode', 'glassmorphism_light').
  final String id;

  /// نقشه مقادیر استایل برای تم فعلی.
  /// کلیدها نام ویژگی (مانند 'primaryColor') و مقادیر، داده‌های آن هستند.
  final Map<String, dynamic> properties;

  ThemeComponent({required this.id, this.properties = const {}});

  /// یک کامپوننت را از داده‌های JSON بازسازی می‌کند.
  factory ThemeComponent.fromJson(Map<String, dynamic> json) {
    return ThemeComponent(
      id: json['id'] as String,
      properties: Map<String, dynamic>.from(json['properties']),
    );
  }

  /// این کامپوننت را به یک نقشه JSON تبدیل می‌کند.
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'properties': properties,
      };

  @override
  List<Object?> get props => [id, properties];
}
