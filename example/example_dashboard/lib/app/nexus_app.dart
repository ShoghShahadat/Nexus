import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/app/theme.dart';
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
        // worldProvider یک دنیای Nexus جدید ایجاد کرده و ماژول اصلی داشبورد را در آن بارگذاری می‌کند.
        // این تابع در یک Isolate مجزا (در پلتفرم‌های غیر وب) اجرا می‌شود.
        worldProvider: () => NexusWorld()..loadModule(DashboardModule()),
        // فرزند NexusScope، ویجت اصلی صفحه داشبورد است.
        child: const DashboardScene(),
      ),
    );
  }
}
