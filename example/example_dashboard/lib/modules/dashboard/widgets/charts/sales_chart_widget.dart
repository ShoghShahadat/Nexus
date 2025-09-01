import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';

class SalesChartWidget extends StatelessWidget {
  final EntityId entityId;
  const SalesChartWidget({super.key, required this.entityId});

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
            Text("Sales Trend", style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            Expanded(
              child: EntityBuilder<SalesDataComponent>(
                entityId: entityId,
                builder: (context, component) {
                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: component.spots
                              .map((spot) => FlSpot(spot.x, spot.y))
                              .toList(),
                          isCurved: true,
                          color: theme.primaryColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor.withOpacity(0.3),
                                theme.primaryColor.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
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
