import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// ویجت برای نمایش هدر داشبورد.
class HeaderWidget extends StatelessWidget {
  final EntityId entityId;
  const HeaderWidget({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    return EntityBuilder<CustomWidgetComponent>(
      entityId: entityId,
      builder: (context, component) {
        final theme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(component.properties['title'] ?? 'Dashboard',
                style: theme.headlineMedium),
            Text(component.properties['subtitle'] ?? '',
                style: theme.titleLarge),
          ],
        );
      },
    );
  }
}
