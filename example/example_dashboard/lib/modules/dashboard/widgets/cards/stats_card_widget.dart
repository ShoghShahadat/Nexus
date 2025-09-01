import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

/// ویجت نمایش‌دهنده یک کارت آمار.
/// این ویجت به صورت واکنشی به تغییرات داده‌های خود گوش می‌دهد.
class StatsCardWidget extends StatelessWidget {
  final EntityId entityId;

  const StatsCardWidget({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    // استفاده از EntityBuilder برای گوش دادن به تغییرات StatsCardComponent.
    // این ویجت تنها زمانی بازسازی می‌شود که داده‌های این کارت خاص تغییر کند.
    return EntityBuilder<StatsCardComponent>(
      entityId: entityId,
      loadingBuilder: (context) =>
          const Card(child: Center(child: CircularProgressIndicator())),
      builder: (context, stats) {
        final color = Color(stats.colorValue);
        final textTheme = Theme.of(context).textTheme;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stats.title, style: textTheme.labelSmall),
                    Icon(
                      IconData(stats.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      color: color,
                      size: 24,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats.value,
                        style: textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    _TrendIndicator(trend: stats.trend),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// یک ویجت کوچک برای نمایش نشانگر روند (صعودی/نزولی).
class _TrendIndicator extends StatelessWidget {
  final Trend trend;
  const _TrendIndicator({required this.trend});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String text;

    switch (trend) {
      case Trend.up:
        icon = Icons.arrow_upward;
        color = Colors.green;
        text = 'Increased';
        break;
      case Trend.down:
        icon = Icons.arrow_downward;
        color = Colors.red;
        text = 'Decreased';
        break;
      case Trend.neutral:
        icon = Icons.horizontal_rule;
        color = Colors.grey;
        text = 'Stable';
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
