import 'package:nexus/nexus.dart';

/// Enum برای نمایش روند (Trend) آمار.
enum Trend { up, down, stable }

/// یک کامپوننت داده‌محور که وضعیت یک کارت آمار را نگهداری می‌کند.
class StatsCardComponent extends Component with SerializableComponent {
  final String title;
  final int iconData; // کد آیکون از فونت متریال
  final String value;
  final Trend trend;
  final bool isLoading;

  StatsCardComponent({
    required this.title,
    required this.iconData,
    required this.value,
    required this.trend,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [title, iconData, value, trend, isLoading];

  /// متد `copyWith` برای ایجاد یک نمونه جدید با مقادیر به‌روز شده.
  StatsCardComponent copyWith({
    String? title,
    int? iconData,
    String? value,
    Trend? trend,
    bool? isLoading,
  }) {
    return StatsCardComponent(
      title: title ?? this.title,
      iconData: iconData ?? this.iconData,
      value: value ?? this.value,
      trend: trend ?? this.trend,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'iconData': iconData,
        'value': value,
        'trend': trend.index,
        'isLoading': isLoading,
      };

  factory StatsCardComponent.fromJson(Map<String, dynamic> json) {
    return StatsCardComponent(
      title: json['title'] as String,
      iconData: json['iconData'] as int,
      value: json['value'] as String,
      trend: Trend.values[json['trend'] as int],
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }
}
