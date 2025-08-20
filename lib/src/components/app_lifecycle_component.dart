import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/app_lifecycle_event.dart';

/// A serializable component that holds the current lifecycle state of the application.
/// یک کامپوننت سریالایزبل که وضعیت فعلی چرخه حیات برنامه را نگهداری می‌کند.
///
/// Typically, only one entity (e.g., a 'root' or 'world' entity) will have this
/// component. The `AppLifecycleSystem` is responsible for keeping it updated.
/// معمولاً فقط یک موجودیت (مانند موجودیت 'root') این کامپوننت را خواهد داشت.
/// سیستم `AppLifecycleSystem` مسئول به‌روز نگه داشتن آن است.
class AppLifecycleComponent extends Component with SerializableComponent {
  final AppLifecycleStatus status;

  AppLifecycleComponent(this.status);

  factory AppLifecycleComponent.fromJson(Map<String, dynamic> json) {
    return AppLifecycleComponent(
      AppLifecycleStatus.values[json['status'] as int],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'status': status.index,
      };

  @override
  List<Object?> get props => [status];
}
