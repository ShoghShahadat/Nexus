import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

/// ویجت برای نمایش یک کارت آمار.
class StatsCardWidget extends StatelessWidget {
  final EntityId entityId;
  const StatsCardWidget({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    // این ویجت به تغییرات StatsCardComponent گوش می‌دهد و تنها در صورت نیاز بازسازی می‌شود.
    return EntityBuilder<StatsCardComponent>(
      entityId: entityId,
      builder: (context, card) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        IconData trendIcon;
        Color trendColor;
        switch (card.trend) {
          case Trend.up:
            trendIcon = Icons.arrow_upward;
            trendColor = Colors.green;
            break;
          case Trend.down:
            trendIcon = Icons.arrow_downward;
            trendColor = Colors.red;
            break;
          // FIX: Corrected 'neutral' to 'stable' to match the enum definition.
          // اصلاح: مقدار 'neutral' به 'stable' برای تطابق با تعریف enum تغییر یافت.
          case Trend.stable:
            trendIcon = Icons.remove;
            trendColor = Colors.grey;
            break;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  // FIX: Used theme color instead of a non-existent component property.
                  // اصلاح: از رنگ تم به جای یک پراپرتی ناموجود در کامپوننت استفاده شد.
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                      // FIX: Correctly accessed `iconData` instead of `iconCodePoint`.
                      // اصلاح: دسترسی به `iconData` به جای `iconCodePoint` تصحیح شد.
                      IconData(card.iconData, fontFamily: 'MaterialIcons'),
                      color: colorScheme.primary,
                      size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      if (card.isLoading)
                        const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Text(card.value, style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                Icon(trendIcon, color: trendColor, size: 28),
              ],
            ),
          ),
        );
      },
    );
  }
}
