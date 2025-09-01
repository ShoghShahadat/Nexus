import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';

class UserActivityWidget extends StatelessWidget {
  final UserActivityDataComponent data;

  const UserActivityWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Activity', style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                _mainData(theme),
                // FIX: Replaced deprecated parameter with the current correct API.
                // اصلاح: پارامتر منسوخ شده با API صحیح فعلی جایگزین شد.
                swapAnimationDuration: const Duration(milliseconds: 500),
                swapAnimationCurve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _mainData(ThemeData theme) {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${data.bars[groupIndex].label}\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: (rod.toY - 1).toString(),
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) =>
                _getTitles(value, meta, theme.textTheme),
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: _buildBarGroups(),
      gridData: const FlGridData(show: false),
    );
  }

  Widget _getTitles(double value, TitleMeta meta, TextTheme textTheme) {
    final int index = value.toInt();
    if (index >= 0 && index < data.bars.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 16,
        child: Text(data.bars[index].label,
            style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
      );
    }
    return Container();
  }

  List<BarChartGroupData> _buildBarGroups() {
    return data.bars
        .asMap()
        .map((index, barData) => MapEntry(
            index,
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: barData.y,
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pinkAccent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                )
              ],
            )))
        .values
        .toList();
  }
}
