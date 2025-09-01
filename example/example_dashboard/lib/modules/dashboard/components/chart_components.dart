import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';

/// یک کلاس داده برای نگهداری اطلاعات یک نقطه در نمودار خطی.
class ChartSpot with EquatableMixin {
  final double x;
  final double y;

  ChartSpot({required this.x, required this.y});

  factory ChartSpot.fromJson(Map<String, dynamic> json) {
    return ChartSpot(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  List<Object?> get props => [x, y];
}

/// کامپوننتی برای نگهداری داده‌های نمودار فروش.
class SalesDataComponent extends Component with SerializableComponent {
  final List<ChartSpot> spots;

  SalesDataComponent(this.spots);

  factory SalesDataComponent.fromJson(Map<String, dynamic> json) {
    return SalesDataComponent(
      (json['spots'] as List)
          .map((spotJson) => ChartSpot.fromJson(spotJson))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {'spots': spots.map((s) => s.toJson()).toList()};

  @override
  List<Object?> get props => [spots];
}

/// یک کلاس داده برای نگهداری اطلاعات یک میله در نمودار میله‌ای.
class ChartBar with EquatableMixin {
  final double x;
  final double y;
  final String label;

  ChartBar({required this.x, required this.y, required this.label});

  factory ChartBar.fromJson(Map<String, dynamic> json) {
    return ChartBar(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'label': label};

  @override
  List<Object?> get props => [x, y, label];
}

/// کامپوننتی برای نگهداری داده‌های نمودار فعالیت کاربران.
class UserActivityDataComponent extends Component with SerializableComponent {
  final List<ChartBar> bars;

  UserActivityDataComponent(this.bars);

  factory UserActivityDataComponent.fromJson(Map<String, dynamic> json) {
    return UserActivityDataComponent(
      (json['bars'] as List)
          .map((barJson) => ChartBar.fromJson(barJson))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {'bars': bars.map((b) => b.toJson()).toList()};

  @override
  List<Object?> get props => [const DeepCollectionEquality().hash(bars)];
}
