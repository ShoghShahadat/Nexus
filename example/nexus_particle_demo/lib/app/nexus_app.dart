import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The root widget of the application.
/// ویجت ریشه برنامه.
///
/// This widget sets up the MaterialApp with the provided GoRouter instance.
/// این ویجت MaterialApp را با نمونه GoRouter ارائه‌شده راه‌اندازی می‌کند.
class NexusDemoApp extends StatelessWidget {
  final GoRouter router;

  const NexusDemoApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nexus Particle Demo',
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      // Use the router for navigation.
      // استفاده از روتر برای ناوبری.
      routerConfig: router,
    );
  }
}
