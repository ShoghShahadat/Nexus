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
  // FIX: All context-dependent fields are now late-initialized.
  // اصلاح: تمام فیلدهای وابسته به context اکنون به صورت late مقداردهی اولیه می‌شوند.
  late ComponentCache _cache;
  late ChangeNotifier _notifier;
  T? _component;
  bool _isDisposed = false;
  bool _dependenciesInitialized = false;

  @override
  void initState() {
    super.initState();
    // Defer context-dependent initialization to didChangeDependencies.
    // مقداردهی اولیه وابسته به context به didChangeDependencies موکول می‌شود.
  }

  // FIX: Moved context-dependent initialization here.
  // This method is the correct place to access InheritedWidgets.
  // اصلاح: مقداردهی اولیه وابسته به context به اینجا منتقل شد.
  // این متد جای مناسبی برای دسترسی به InheritedWidgetها است.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesInitialized) {
      _cache = NexusScope.cacheOf(context);
      _notifier = _cache.getNotifier(widget.entityId);
      _notifier.addListener(_onComponentChanged);

      _component = _cache.get<T>(widget.entityId);
      _dependenciesInitialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant EntityBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entityId != oldWidget.entityId) {
      // If the entityId changes, we need to listen to the new notifier.
      // اگر entityId تغییر کند، باید به notifier جدید گوش دهیم.
      _notifier.removeListener(_onComponentChanged);
      _notifier = _cache.getNotifier(widget.entityId);
      _notifier.addListener(_onComponentChanged);
      _onComponentChanged();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Ensure notifier is initialized before trying to remove a listener.
    // اطمینان حاصل می‌کنیم که notifier قبل از حذف listener مقداردهی شده است.
    if (_dependenciesInitialized) {
      _notifier.removeListener(_onComponentChanged);
    }
    super.dispose();
  }

  void _onComponentChanged() {
    if (_isDisposed) return;
    final newComponent = _cache.get<T>(widget.entityId);

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
