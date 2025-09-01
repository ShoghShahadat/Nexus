import 'dart:math';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';
import 'package:intl/intl.dart';

/// یک کلاس برای شبیه‌سازی دریافت داده‌های جدید از یک API.
class MockApiService {
  final _random = Random();
  final _numberFormat = NumberFormat.decimalPattern('en_us');

  /// یک متد شبیه‌سازی شده که پس از یک تاخیر کوتاه، داده‌های جدید را برمی‌گرداند.
  Future<({String value, Trend trend})> fetchUpdatedStats(String title) async {
    // شبیه‌سازی تاخیر شبکه
    await Future.delayed(Duration(milliseconds: _random.nextInt(800) + 200));

    // تولید داده‌های تصادفی جدید
    final newValue = _random.nextInt(100000) + 500;
    final newTrend = Trend.values[_random.nextInt(Trend.values.length)];

    return (value: _formatValue(title, newValue), trend: newTrend);
  }

  /// قالب‌بندی مقدار بر اساس عنوان کارت.
  String _formatValue(String title, int value) {
    if (title.toLowerCase() == 'revenue') {
      return '\$${_numberFormat.format(value * 120)}';
    }
    if (title.toLowerCase() == 'engagement') {
      return '${(value / 1000).toStringAsFixed(1)}%';
    }
    return _numberFormat.format(value);
  }
}
