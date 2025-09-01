import 'package:example_dashboard/app/nexus_app.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// نقطه شروع اصلی برنامه فلاتر.
void main() {
  // --- CRITICAL FIX: Register custom components for the UI thread ---
  // این تابع باید قبل از اجرای برنامه فراخوانی شود تا ترد UI
  // فکتوری‌های لازم برای ساخت کامپوننت‌های سفارشی را بشناسد.
  registerDashboardComponents();
  runApp(const DashboardApp());
}

/// کامپوننت‌های سفارشی مربوط به ماژول داشبورد را ثبت می‌کند.
void registerDashboardComponents() {
  ComponentFactoryRegistry.I.register(
    'StatsCardComponent',
    (json) => StatsCardComponent.fromJson(json),
  );
  // در آینده، تمام کامپوننت‌های سفارشی دیگر این ماژول را اینجا ثبت کنید.
}
