import 'package:nexus/nexus.dart';

/// یک شیء انتقال داده (DTO) که برای ارسال به‌روزرسانی‌های یک کامپوننت
/// از ایزوله منطق به ترد UI استفاده می‌شود.
/// این جایگزین سبک و بهینه RenderPacket است.
class ComponentUpdate {
  final EntityId entityId;
  final String componentTypeName;
  final Map<String, dynamic>? componentJson;
  final bool isRemoved;

  ComponentUpdate({
    required this.entityId,
    required this.componentTypeName,
    this.componentJson,
    this.isRemoved = false,
  });
}
