import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';

class SalesChartWidget extends StatelessWidget {
  final SalesDataComponent data;

  const SalesChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales This Year', style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                _mainData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 0.1,
          );
        },
      ),
      titlesData: const FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 0.2),
      ),
      minX: 1,
      maxX: 12,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: data.spots.map((s) => FlSpot(s.x, s.y)).toList(),
          isCurved: true,
          gradient: const LinearGradient(
            colors: [Colors.cyan, Colors.blue],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.cyan.withOpacity(0.3),
                Colors.blue.withOpacity(0.3)
              ],
            ),
          ),
        ),
      ],
    );
  }
}
