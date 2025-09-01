import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';
import 'package:example_dashboard/services/mock_api_service.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// Assembler برای ایجاد موجودیت‌های مربوط به نمودارها.
class ChartsAssembler extends EntityAssembler<EntityId> {
  final MockApiService _apiService = MockApiService();

  ChartsAssembler(NexusWorld world, EntityId context) : super(world, context);

  @override
  List<Entity> assemble() {
    final salesChart = _buildSalesChart();
    final userActivityChart = _buildUserActivityChart();

    // یک کانتینر برای نمودارها ایجاد می‌کنیم
    final chartsContainer = Entity()
      ..add(TagsComponent({'charts_container'}))
      ..add(ParentComponent(context)) // فرزند ریشه
      ..add(ChildrenComponent([salesChart.id, userActivityChart.id]));

    world.addEntity(chartsContainer);

    return [chartsContainer, salesChart, userActivityChart];
  }

  Entity _buildSalesChart() {
    final entity = Entity()
      ..add(TagsComponent({'sales_chart'}))
      ..add(ApiRequestComponent(
        url: '/api/sales',
        onParse: (json) {
          return [SalesDataComponent.fromJson(json)];
        },
      ));
    world.addEntity(entity);
    return entity;
  }

  Entity _buildUserActivityChart() {
    final entity = Entity()
      ..add(TagsComponent({'user_activity_chart'}))
      // درخواست اولیه داده‌ها از طریق API
      ..add(ApiRequestComponent(
        url: '/api/user_activity',
        onParse: (json) => [UserActivityDataComponent.fromJson(json)],
      ))
      // کامپوننت برای اتصال به وب‌سوکت و دریافت آپدیت‌های زنده
      ..add(WebSocketRequestComponent(
          url: 'ws://localhost:8080/user_activity',
          connectionId: 'user_activity_stream',
          onParseMessage: (data) {
            // FIX: Safely cast the incoming dynamic map to the required type.
            // اصلاح: تبدیل نوع امن نقشه داینامیک ورودی به نوع مورد نیاز.
            if (data is Map) {
              final typedMap = Map<String, dynamic>.from(data);
              return [UserActivityDataComponent.fromJson(typedMap)];
            }
            return [];
          }));
    world.addEntity(entity);
    return entity;
  }
}
