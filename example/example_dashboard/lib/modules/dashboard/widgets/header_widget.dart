import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

class HeaderWidget extends StatelessWidget {
  final String entityTag;

  const HeaderWidget({super.key, required this.entityTag});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // این ویجت در حال حاضر استاتیک است، اما با EntityBuilder می‌توان آن را
    // به داده‌های دینامیک (مانند نام کاربر) متصل کرد.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dashboard Overview', style: textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Welcome back, User!', style: textTheme.bodySmall),
      ],
    );
  }
}
