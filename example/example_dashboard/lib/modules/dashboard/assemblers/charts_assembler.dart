import 'package:nexus/nexus.dart';
import 'package:example_dashboard/services/mock_api_service.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';

/// مسئول ایجاد موجودیت‌های نمودارها.
class ChartsAssembler extends EntityAssembler {
  ChartsAssembler(super.world, super.context);

  @override
  List<Entity> assemble() {
    final apiService = world.services.get<MockApiService>();

    // --- Sales Chart Entity ---
    final salesChartEntity = Entity();
    world.addEntity(salesChartEntity);
    final salesData = apiService.fetchSalesData();
    final salesSpots = (salesData['spots'] as List)
        .map((spot) =>
            Spot((spot['x'] as num).toDouble(), (spot['y'] as num).toDouble()))
        .toList();

    salesChartEntity.add(SalesDataComponent(spots: salesSpots));

    // --- User Activity Chart Entity ---
    final userActivityEntity = Entity();
    world.addEntity(userActivityEntity);
    final activityData = apiService.fetchUserActivityData();
    final activityBars = (activityData['bars'] as List)
        .map((bar) => Bar(
              (bar['x'] as num).toDouble(),
              (bar['y'] as num).toDouble(),
              bar['label'] as String,
            ))
        .toList();

    userActivityEntity.add(UserActivityDataComponent(bars: activityBars));

    return [salesChartEntity, userActivityEntity];
  }
}
