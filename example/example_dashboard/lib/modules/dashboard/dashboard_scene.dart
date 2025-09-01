import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/shared/components/tags.dart';
import 'package:example_dashboard/modules/dashboard/widgets/header_widget.dart';
import 'package:example_dashboard/modules/dashboard/widgets/cards/stats_card_builder.dart';
import 'package:example_dashboard/modules/dashboard/widgets/charts/sales_chart_widget.dart';
import 'package:example_dashboard/modules/dashboard/widgets/charts/user_activity_widget.dart';

/// ویجت اصلی که صحنه داشبورد را نمایش می‌دهد.
class DashboardScene extends StatefulWidget {
  const DashboardScene({super.key});

  @override
  State<DashboardScene> createState() => _DashboardSceneState();
}

class _DashboardSceneState extends State<DashboardScene> {
  bool _isReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isReady) {
      // منتظر می‌مانیم تا اولین بسته داده از ایزوله منطق برسد.
      final cache = NexusScope.cacheOf(context);
      cache.onReady.then((_) {
        if (mounted) {
          setState(() => _isReady = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              EntityBuilder<TagsComponent>(
                entityId: 1, // Assuming header is entity 1
                builder: (context, _) => HeaderWidget(entityId: 1),
              ),
              const SizedBox(height: 24),
              // 2. Main content grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // --- Responsive Grid Layout ---
                    final crossAxisCount =
                        (constraints.maxWidth / 350).floor().clamp(1, 4);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                      children: const [
                        // --- Stats Cards ---
                        StatsCardWidget(entityId: 2), // Revenue
                        StatsCardWidget(entityId: 3), // Users
                        StatsCardWidget(entityId: 4), // Orders
                        StatsCardWidget(entityId: 5), // Engagement
                        // --- Charts ---
                        SalesChartWidget(entityId: 6),
                        UserActivityWidget(entityId: 7),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
