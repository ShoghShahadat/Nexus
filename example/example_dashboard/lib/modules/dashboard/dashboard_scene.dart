import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/widgets/header_widget.dart';
import 'package:example_dashboard/modules/dashboard/widgets/cards/stats_card_widget.dart';

/// ویجت اصلی که صفحه داشبورد را رندر می‌کند.
/// REFACTORED: This scene now builds its layout based on the root entity with the
/// fixed and predictable ID of 0. This removes the race condition.
/// بازآفرینی: این صفحه اکنون لایوت خود را بر اساس Entity ریشه با شناسه
/// ثابت و قابل پیش‌بینی 0 می‌سازد. این کار race condition را برطرف می‌کند.
class DashboardScene extends StatelessWidget {
  const DashboardScene({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // EntityBuilder به دنبال Entity ریشه با شناسه ثابت 0 می‌گردد.
        child: EntityBuilder<ChildrenComponent>(
          entityId: 0, // Root entity always has ID 0
          loadingBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error) =>
              Center(child: Text('Error: $error')),
          builder: (context, rootChildren) {
            // ID های هدر و کانتینر کارت‌ها از Entity ریشه خوانده می‌شود.
            final headerId = rootChildren.children[0];
            final cardContainerId = rootChildren.children[1];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderWidget(entityId: headerId),
                  const SizedBox(height: 24),
                  Expanded(
                    child: EntityBuilder<ChildrenComponent>(
                      entityId: cardContainerId,
                      builder: (context, cardContainerChildren) {
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 3 / 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: cardContainerChildren.children.length,
                          itemBuilder: (context, index) {
                            final entityId =
                                cardContainerChildren.children[index];
                            return StatsCardWidget(entityId: entityId);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
