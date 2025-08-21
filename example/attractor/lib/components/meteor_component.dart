import 'package:nexus/nexus.dart';

/// A component that marks an entity as a meteor.
/// Health is now managed by the standard HealthComponent.
/// کامپوننتی که یک موجودیت را به عنوان شهاب‌سنگ علامت‌گذاری می‌کند.
/// "جان" اکنون توسط HealthComponent استاندارد مدیریت می‌شود.
class MeteorComponent extends Component with SerializableComponent {
  MeteorComponent(); // No longer needs health

  factory MeteorComponent.fromJson(Map<String, dynamic> json) {
    return MeteorComponent();
  }

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}
