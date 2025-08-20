import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';

// --- تحلیل اولیه ---
// این فایل یک اپلیکیشن شمارنده کاملاً کاربردی و ساده را با استفاده از فریم‌ورک Nexus پیاده‌سازی می‌کند.
// هدف، نمایش مفاهیم اصلی ECS در یک سناریوی واقعی اما بدون پیچیدگی‌های اضافی است.
//
// معماری:
// 1. NexusWorld در یک Isolate پس‌زمینه اجرا می‌شود تا منطق برنامه، UI را مسدود نکند.
// 2. یک CounterCubit (از پکیج BLoC) به عنوان سرویس برای مدیریت وضعیت شمارنده ثبت می‌شود.
// 3. سه Entity ایجاد می‌شود: یکی برای نمایش عدد شمارنده، و دو تا برای دکمه‌های افزایش و کاهش.
// 4. دو System اصلی وجود دارد:
//    - CounterSystem: به تغییرات Cubit گوش می‌دهد و کامپوننت داده‌ای شمارنده (CounterStateComponent) را به‌روز می‌کند.
//    - InputSystem: رویدادهای کلیک از UI را دریافت کرده و متدهای Cubit را فراخوانی می‌کند.
// 5. FlutterRenderingSystem در UI Thread اجرا می‌شود و بر اساس داده‌های دریافتی از Isolate پس‌زمینه،
//    ویجت‌های متناظر را می‌سازد.

/// تابع اصلی که NexusWorld را برای Isolate پس‌زمینه فراهم می‌کند.
NexusWorld provideCounterWorld() {
  final world = NexusWorld();

  // 1. ثبت سرویس‌ها: CounterCubit به عنوان یک Singleton ثبت می‌شود.
  // تمام سیستم‌ها و موجودیت‌ها در این World به این نمونه دسترسی خواهند داشت.
  final cubit = CounterCubit();
  world.services.registerSingleton(cubit);

  // 2. افزودن سیستم‌ها:
  world.addSystem(
      CounterSystem()); // سیستمی برای همگام‌سازی وضعیت Cubit با Entity.
  world.addSystem(
      InputSystem()); // سیستمی برای مدیریت ورودی‌های کاربر (کلیک‌ها).

  // 3. ایجاد موجودیت‌ها (Entities):

  // موجودیت برای نمایشگر شمارنده
  final counterDisplay = Entity();
  counterDisplay
      .add(PositionComponent(x: 100, y: 200, width: 200, height: 100));
  counterDisplay.add(BlocComponent<CounterCubit, int>(cubit)); // اتصال به Cubit
  counterDisplay.add(CounterStateComponent(cubit.state)); // نگهداری وضعیت فعلی
  counterDisplay
      .add(TagsComponent({'counter_display'})); // تگ برای شناسایی در UI
  world.addEntity(counterDisplay);

  // موجودیت برای دکمه افزایش
  final incrementButton = Entity();
  incrementButton.add(PositionComponent(x: 210, y: 320, width: 80, height: 50));
  incrementButton
      .add(ClickableComponent((_) => cubit.increment())); // منطق کلیک
  incrementButton.add(TagsComponent({'increment_button'})); // تگ برای UI
  world.addEntity(incrementButton);

  // موجودیت برای دکمه کاهش
  final decrementButton = Entity();
  decrementButton.add(PositionComponent(x: 110, y: 320, width: 80, height: 50));
  decrementButton
      .add(ClickableComponent((_) => cubit.decrement())); // منطق کلیک
  decrementButton.add(TagsComponent({'decrement_button'})); // تگ برای UI
  world.addEntity(decrementButton);

  return world;
}

/// نقطه شروع برنامه Flutter.
void main() {
  // این تابع برای ثبت کامپوننت‌های سریال‌پذیر ضروری است تا ارتباط بین
  // Isolate پس‌زمینه و UI Thread به درستی کار کند.
  registerCoreComponents();
  runApp(const MyApp());
}

/// ویجت اصلی برنامه.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // پیکربندی سیستم رندرینگ که وظیفه تبدیل داده‌های Entity به ویجت‌های Flutter را دارد.
    final renderingSystem = FlutterRenderingSystem(
      builders: {
        // Builder برای نمایشگر شمارنده
        'counter_display': (context, id, controller, manager) {
          final state = controller.get<CounterStateComponent>(id);
          if (state == null) return const SizedBox.shrink();

          return Material(
            color: Colors.transparent,
            child: Center(
              child: Text(
                '${state.value}',
                style:
                    const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
        // Builder برای دکمه افزایش
        'increment_button': (context, id, controller, manager) {
          return ElevatedButton(
            onPressed: () => manager.send(EntityTapEvent(id)),
            child: const Icon(Icons.add),
          );
        },
        // Builder برای دکمه کاهش
        'decrement_button': (context, id, controller, manager) {
          return ElevatedButton(
            onPressed: () => manager.send(EntityTapEvent(id)),
            child: const Icon(Icons.remove),
          );
        },
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nexus Counter Example'),
        ),
        body: NexusWidget(
          worldProvider: provideCounterWorld,
          renderingSystem: renderingSystem,
        ),
      ),
    );
  }
}

/// سیستمی که به تغییرات وضعیت در CounterCubit گوش می‌دهد و
/// CounterStateComponent متناظر را به‌روزرسانی می‌کند.
class CounterSystem extends BlocSystem<CounterCubit, int> {
  @override
  void onStateChange(Entity entity, int state) {
    // هر بار که وضعیت Cubit تغییر می‌کند، این متد فراخوانی شده و
    // کامپوننت داده‌ای Entity را با مقدار جدید به‌روز می‌کند.
    // این تغییر به صورت خودکار به UI ارسال خواهد شد.
    entity.add(CounterStateComponent(state));
  }
}
