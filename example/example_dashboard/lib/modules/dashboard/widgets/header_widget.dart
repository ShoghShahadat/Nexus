import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/header_component.dart';

/// ویجتی که هدر داشبورد را نمایش می‌دهد.
class HeaderWidget extends StatelessWidget {
  final EntityId entityId;
  const HeaderWidget({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return EntityBuilder<HeaderComponent>(
      entityId: entityId,
      loadingBuilder: (context) => const SizedBox(height: 50),
      builder: (context, header) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(header.title, style: textTheme.headlineMedium),
                Text('Welcome back, ${header.userName}!',
                    style: textTheme.titleLarge),
              ],
            ),
            const CircleAvatar(
              radius: 25,
              backgroundImage:
                  NetworkImage('https://i.pravatar.cc/150?u=shahrokh'),
            ),
          ],
        );
      },
    );
  }
}
