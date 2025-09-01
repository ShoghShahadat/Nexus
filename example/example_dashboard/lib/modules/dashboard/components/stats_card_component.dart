import 'package:nexus/nexus.dart';

/// Enum برای نمایش روند (صعودی، نزولی یا خنثی).
enum Trend { up, down, neutral }

/// کامپوننت داده برای نگهداری اطلاعات یک کارت آمار.
class StatsCardComponent extends Component with SerializableComponent {
  final String title;
  final String value;
  final int iconCodePoint;
  final Trend trend;
  final int colorValue;

  StatsCardComponent({
    required this.title,
    required this.value,
    required this.iconCodePoint,
    required this.trend,
    required this.colorValue,
  });

  @override
  List<Object?> get props => [title, value, iconCodePoint, trend, colorValue];

  // --- Serialization ---
  factory StatsCardComponent.fromJson(Map<String, dynamic> json) {
    return StatsCardComponent(
      title: json['title'] as String,
      value: json['value'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      trend: Trend.values[json['trend'] as int],
      colorValue: json['colorValue'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'iconCodePoint': iconCodePoint,
        'trend': trend.index,
        'colorValue': colorValue,
      };
}
