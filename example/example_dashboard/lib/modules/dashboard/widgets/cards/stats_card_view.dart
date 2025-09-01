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
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.cardColor,
              theme.cardColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: theme.textTheme.bodySmall?.color)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                        IconData(data.iconData, fontFamily: 'MaterialIcons'),
                        color: theme.primaryColor,
                        size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey<String>(data.value), // Key for animation
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(data.value, style: theme.textTheme.headlineMedium),
                    const SizedBox(width: 8),
                    if (status.status != ApiStatus.loading)
                      Icon(trendIcon, color: trendColor, size: 20),
                    if (status.status == ApiStatus.loading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTrendColor(Trend trend) {
    switch (trend) {
      case Trend.up:
        return Colors.green.shade400;
      case Trend.down:
        return Colors.red.shade400;
      case Trend.stable:
        return Colors.grey.shade500;
    }
  }

  IconData _getTrendIcon(Trend trend) {
    switch (trend) {
      case Trend.up:
        return Icons.arrow_upward_rounded;
      case Trend.down:
        return Icons.arrow_downward_rounded;
      case Trend.stable:
        return Icons.remove_rounded;
    }
  }
}
