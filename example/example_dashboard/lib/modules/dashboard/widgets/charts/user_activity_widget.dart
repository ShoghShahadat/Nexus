import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';

class UserActivityWidget extends StatelessWidget {
  final EntityId entityId;
  const UserActivityWidget({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User Activity", style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            Expanded(
              child: EntityBuilder<UserActivityDataComponent>(
                entityId: entityId,
                builder: (context, component) {
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(
                              component.bars[value.toInt()].label,
                              style: theme.textTheme.labelSmall,
                            ),
                            reservedSize: 20,
                          ),
                        ),
                      ),
                      barGroups: component.bars
                          .map(
                            (bar) => BarChartGroupData(
                              x: bar.x.toInt(),
                              barRods: [
                                BarChartRodData(
                                  toY: bar.y,
                                  color: theme.primaryColor.withOpacity(0.8),
                                  width: 16,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
