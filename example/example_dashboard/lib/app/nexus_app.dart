import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/app/theme.dart';
import 'package:example_dashboard/main.dart';
import 'package:example_dashboard/modules/dashboard/dashboard_module.dart';
import 'package:example_dashboard/modules/dashboard/dashboard_scene.dart';

/// ویجت ریشه برنامه که NexusScope را برای مدیریت دنیای Nexus فراهم می‌کند.
class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Dashboard Demo',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: NexusScope(
        // --- CRITICAL FIX: Register custom components for the Logic Isolate ---
        // این تابع تضمین می‌کند که ایزوله منطق نیز فکتوری‌های لازم برای
        // کار با کامپوننت‌های سفارشی را در اختیار دارد.
        isolateInitializer: () async {
          registerDashboardComponents();
        },
        worldProvider: () => NexusWorld()..loadModule(DashboardModule()),
        child: const DashboardScene(),
      ),
    );
  }
}
