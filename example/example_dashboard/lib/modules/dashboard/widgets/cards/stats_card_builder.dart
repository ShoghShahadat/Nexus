import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';
import 'package:example_dashboard/modules/dashboard/widgets/cards/stats_card_view.dart';

/// ویجتی که وضعیت یک کارت آمار را مدیریت کرده و ویجت مناسب را نمایش می‌دهد.
class StatsCardWidget extends StatelessWidget {
  final EntityId entityId;

  const StatsCardWidget({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    return EntityBuilder<StatsCardComponent>(
      entityId: entityId,
      loadingBuilder: (context) => const Card(
        child: Center(child: CircularProgressIndicator()),
      ),
      builder: (context, cardData) {
        return EntityBuilder<ApiStatusComponent>(
          entityId: entityId,
          loadingBuilder: (context) => StatsCardView(
            data: cardData,
            status: ApiStatusComponent(status: ApiStatus.idle),
          ),
          builder: (context, status) {
            return StatsCardView(data: cardData, status: status);
          },
        );
      },
    );
  }
}
