import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

class StatsCardWidget extends StatelessWidget {
  final EntityId entityId;

  const StatsCardWidget({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cardColor = Theme.of(context).cardColor;

    return EntityBuilder<StatsCardComponent>(
      entityId: entityId,
      builder: (context, component) {
        return Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                _buildIcon(component),
                const SizedBox(width: 16),
                _buildTextContent(component, textTheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(StatsCardComponent component) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(component.iconColorValue).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        component.icon,
        color: Color(component.iconColorValue),
        size: 28,
      ),
    );
  }

  Widget _buildTextContent(StatsCardComponent component, TextTheme textTheme) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(component.title, style: textTheme.labelSmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(component.value,
                  style:
                      textTheme.headlineSmall?.copyWith(color: Colors.black)),
              const SizedBox(width: 8),
              _buildTrendIndicator(component.trend),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(Trend trend) {
    final isUp = trend == Trend.up;
    return Icon(
      isUp ? Icons.arrow_upward : Icons.arrow_downward,
      color: isUp ? Colors.green : Colors.red,
      size: 16,
    );
  }
}
