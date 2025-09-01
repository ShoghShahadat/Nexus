import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

/// یک ویجت نمایشی خالص که داده‌های یک کارت آمار را نمایش می‌دهد.
class StatsCardView extends StatelessWidget {
  final StatsCardComponent data;
  final ApiStatusComponent status;

  const StatsCardView({
    super.key,
    required this.data,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = _getTrendColor(data.trend);
    final trendIcon = _getTrendIcon(data.trend);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.title, style: theme.textTheme.titleLarge),
                Icon(IconData(data.iconData, fontFamily: 'MaterialIcons'),
                    color: theme.primaryColor, size: 32),
              ],
            ),
            const SizedBox(height: 8),
            if (status.status == ApiStatus.loading)
              const Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3)))
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(data.value, style: theme.textTheme.headlineMedium),
                  const SizedBox(width: 8),
                  Icon(trendIcon, color: trendColor, size: 20),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getTrendColor(Trend trend) {
    switch (trend) {
      case Trend.up:
        return Colors.green;
      case Trend.down:
        return Colors.red;
      case Trend.stable:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(Trend trend) {
    switch (trend) {
      case Trend.up:
        return Icons.arrow_upward;
      case Trend.down:
        return Icons.arrow_downward;
      case Trend.stable:
        return Icons.remove;
    }
  }
}
