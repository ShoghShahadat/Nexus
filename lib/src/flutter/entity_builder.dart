import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/flutter/component_cache.dart';
import 'package:nexus/src/flutter/nexus_scope.dart';

/// یک ویجت واکنشی که به تغییرات یک کامپوننت خاص روی یک موجودیت گوش می‌دهد
/// و تنها در صورت نیاز، خود را بازسازی (rebuild) می‌کند.
/// این ویجت قلب تپنده معماری ESCUEM در لایه UI است.
class EntityBuilder<T extends Component> extends StatefulWidget {
  final EntityId entityId;
  final Widget Function(BuildContext context, T component) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const EntityBuilder({
    super.key,
    required this.entityId,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<EntityBuilder<T>> createState() => _EntityBuilderState<T>();
}

class _EntityBuilderState<T extends Component> extends State<EntityBuilder<T>> {
  late final ComponentCache _cache;
  late final ChangeNotifier _notifier;
  T? _component;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // ویجت به محض ساخته شدن، به cache دسترسی پیدا کرده و برای دریافت
    // به‌روزرسانی‌ها ثبت‌نام می‌کند.
    _cache = NexusScope.cacheOf(context);
    _notifier = _cache.getNotifier(widget.entityId);
    _notifier.addListener(_onComponentChanged);

    // سعی می‌کنیم مقدار اولیه کامپوننت را از کش بخوانیم.
    _component = _cache.get<T>(widget.entityId);
  }

  @override
  void didUpdateWidget(covariant EntityBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entityId != oldWidget.entityId) {
      // اگر entityId تغییر کند، اشتراک قبلی را لغو و اشتراک جدیدی ایجاد می‌کنیم.
      _notifier.removeListener(_onComponentChanged);
      _notifier = _cache.getNotifier(widget.entityId);
      _notifier.addListener(_onComponentChanged);
      _onComponentChanged();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _notifier.removeListener(_onComponentChanged);
    super.dispose();
  }

  void _onComponentChanged() {
    if (_isDisposed) return;
    final newComponent = _cache.get<T>(widget.entityId);

    // تنها در صورتی rebuild می‌کنیم که نمونه کامپوننت واقعاً تغییر کرده باشد.
    if (!identical(_component, newComponent)) {
      setState(() {
        _component = newComponent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_component == null) {
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    }
    return widget.builder(context, _component as T);
  }
}
