import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/shared/components/tags.dart';
import 'package:example_dashboard/modules/dashboard/widgets/header_widget.dart';
import 'package:example_dashboard/modules/dashboard/widgets/stats_card_widget.dart';
import 'package:example_dashboard/modules/dashboard/widgets/charts/sales_chart_widget.dart';
import 'package:example_dashboard/modules/dashboard/widgets/charts/user_activity_widget.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';

/// ویجت اصلی که صحنه داشبورد را رندر می‌کند.
class DashboardScene extends StatelessWidget {
  const DashboardScene({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // منتظر می‌مانیم تا اولین بچ داده از ایزوله منطق برسد
          child: FutureBuilder(
            future: NexusScope.cacheOf(context).onReady,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              return const _DashboardLayout();
            },
          ),
        ),
      ),
    );
  }
}

/// لایه‌بندی اصلی داشبورد.
class _DashboardLayout extends StatelessWidget {
  const _DashboardLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeaderWidget(entityTag: DashboardTags.header),
          const SizedBox(height: 24),
          const _StatsGrid(),
          const SizedBox(height: 24),
          _ChartSection(),
        ],
      ),
    );
  }
}

/// گرید نمایش کارت‌های آمار.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final world = NexusScope.of(context).world!;

    // FIX: Simplified and robust entity ID lookup.
    // We find the container entity by its unique tag.
    // اصلاح: منطق پیدا کردن شناسه موجودیت ساده و پایدار شد.
    // کانتینر را با تگ یکتای آن پیدا می‌کنیم.
    final containerEntityId = world.entities.values
        .firstWhere((e) =>
            e.get<TagsComponent>()?.hasTag(DashboardTags.statsCardContainer) ??
            false)
        .id;

    // با استفاده از EntityBuilder به کانتینر کارت‌ها گوش می‌دهیم تا لیست فرزندان آن را بگیریم
    return EntityBuilder<ChildrenComponent>(
      entityId: containerEntityId,
      builder: (context, childrenComp) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
          ),
          itemCount: childrenComp.children.length,
          itemBuilder: (context, index) {
            final cardEntityId = childrenComp.children[index];
            // FIX: Add const to constructor call.
            // اصلاح: اضافه کردن const به فراخوانی سازنده.
            return StatsCardWidget(entityId: cardEntityId);
          },
        );
      },
    );
  }
}

/// بخش نمایش نمودارها.
class _ChartSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final world = NexusScope.of(context).world!;

    // FIX: Simplified and robust entity ID lookup using tags.
    // اصلاح: منطق پیدا کردن شناسه موجودیت با استفاده از تگ‌ها ساده و پایدار شد.
    final salesChartEntityId = world.entities.values
        .firstWhere(
            (e) => e.get<TagsComponent>()?.hasTag('sales_chart') ?? false)
        .id;
    final userActivityChartEntityId = world.entities.values
        .firstWhere((e) =>
            e.get<TagsComponent>()?.hasTag('user_activity_chart') ?? false)
        .id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // نمودار فروش
        Expanded(
          flex: 3,
          child: EntityBuilder<SalesDataComponent>(
            entityId: salesChartEntityId,
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            builder: (context, salesData) {
              // FIX: Pass the 'data' argument, which is what the widget expects.
              // اصلاح: ارسال آرگومان 'data' که ویجت انتظار آن را دارد.
              return SalesChartWidget(data: salesData);
            },
          ),
        ),
        const SizedBox(width: 24),
        // نمودار فعالیت کاربران
        Expanded(
          flex: 2,
          child: EntityBuilder<UserActivityDataComponent>(
            entityId: userActivityChartEntityId,
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            builder: (context, activityData) {
              // FIX: Pass the 'data' argument, which is what the widget expects.
              // اصلاح: ارسال آرگومان 'data' که ویجت انتظار آن را دارد.
              return UserActivityWidget(data: activityData);
            },
          ),
        ),
      ],
    );
  }
}
