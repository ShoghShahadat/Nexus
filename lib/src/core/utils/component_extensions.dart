import 'package:nexus/nexus.dart';
import 'package:nexus/src/core/serialization/component_factory.dart';
import 'package:nexus/src/core/serialization/serializable_component.dart';

/// یک اکستنشن قدرتمند بر روی کلاس پایه `Component`.
/// این اکستنشن یک متد `copyWith` را به تمام کامپوننت‌های سریالایزبل اضافه می‌کند،
/// بدون اینکه نیازی به تغییر در کد اصلی آن‌ها باشد.
extension ComponentCopyWithExtension on Component {
  /// یک نمونه جدید از کامپوننت را با مقادیر به‌روز شده ایجاد می‌کند.
  ///
  /// این متد از مکانیزم سریال‌سازی JSON برای دستیابی به عدم تغییرپذیری (immutability) استفاده می‌کند.
  ///
  /// [updates]: یک نقشه (Map) از پراپرتی‌هایی که باید تغییر کنند.
  ///
  /// مثال:
  /// final newPos = positionComponent.copyWith({'x': 100, 'y': 50});
  T copyWith<T extends Component>(Map<String, dynamic> updates) {
    // اگر کامپوننت قابل سریال‌سازی نباشد، نمی‌توان آن را کپی کرد.
    // در این حالت، همان نمونه اصلی را برمی‌گردانیم.
    if (this is! SerializableComponent) {
      return this as T;
    }

    final serializable = this as SerializableComponent;

    // ۱. کامپوننت فعلی را به JSON تبدیل می‌کنیم.
    final currentJson = serializable.toJson();

    // ۲. مقادیر جدید را با مقادیر فعلی ادغام می‌کنیم.
    // مقادیر موجود در `updates` مقادیر موجود در `currentJson` را بازنویسی می‌کنند.
    final newJson = {...currentJson, ...updates};

    // ۳. نام نوع کامپوننت را برای استفاده در فکتوری به دست می‌آوریم.
    final componentTypeName = runtimeType.toString();

    // ۴. با استفاده از فکتوری، یک نمونه کاملاً جدید از کامپوننت را از روی JSON جدید می‌سازیم.
    final newComponent =
        ComponentFactoryRegistry.I.create(componentTypeName, newJson);

    // ۵. نمونه جدید را با نوع صحیح برمی‌گردانیم.
    return newComponent as T;
  }
}
