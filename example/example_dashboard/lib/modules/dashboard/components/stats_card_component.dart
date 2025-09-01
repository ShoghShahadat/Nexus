import 'package:nexus/nexus.dart';
import 'package:flutter/material.dart';

/// Enum برای نمایش روند داده‌ها (صعودی یا نزولی).
enum Trend {
  up,
  down,
  stable,
}

/// کامپوننتی برای نگهداری داده‌های یک کارت آمار.
class StatsCardComponent extends Component with SerializableComponent {
  final String title;
  final String value;
  final Trend trend;
  final IconData icon;
  final int iconColorValue;

  StatsCardComponent({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.iconColorValue,
  });

  factory StatsCardComponent.fromJson(Map<String, dynamic> json) {
    return StatsCardComponent(
      title: json['title'] as String,
      value: json['value'] as String,
      trend: Trend.values[json['trend_index'] as int],
      icon: IconData(json['icon_code'] as int,
          fontFamily: json['icon_font_family'] as String),
      iconColorValue: json['icon_color_value'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'trend_index': trend.index,
        'icon_code': icon.codePoint,
        'icon_font_family': icon.fontFamily,
        'icon_color_value': iconColorValue,
      };

  @override
  List<Object?> get props => [title, value, trend, icon, iconColorValue];
}
