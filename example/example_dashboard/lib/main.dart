import 'package:example_dashboard/app/nexus_app.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:example_dashboard/modules/dashboard/components/chart_components.dart';
import 'package:example_dashboard/modules/dashboard/components/stats_card_component.dart';

// --- NEW: A dedicated function to register custom components for this app ---
// --- جدید: یک تابع اختصاصی برای ثبت کامپوننت‌های سفارشی این برنامه ---
void registerDashboardComponents() {
  final registry = ComponentFactoryRegistry.I;
  registry.register('StatsCardComponent',
      (json) => StatsCardComponent.fromJson(json), StatsCardComponent);
  registry.register('SalesDataComponent',
      (json) => SalesDataComponent.fromJson(json), SalesDataComponent);
  registry.register(
      'UserActivityDataComponent',
      (json) => UserActivityDataComponent.fromJson(json),
      UserActivityDataComponent);
}

/// The main entry point for the Flutter application.
void main() {
  // --- CRITICAL FIX: Register ALL components on the UI thread BEFORE running the app ---
  // --- اصلاح حیاتی: تمام کامپوننت‌ها را در ترد UI قبل از اجرای برنامه ثبت می‌کند ---
  registerCoreComponents();
  registerDashboardComponents();

  // This function runs the root widget of the application, DashboardApp.
  runApp(const DashboardApp());
}
