import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus_example/particle_painter.dart';

// این تابع در ایزوله پس‌زمینه اجرا خواهد شد و دنیای NexusWorld را فراهم می‌کند.
NexusWorld provideCosmicWorld() {
  final world = NexusWorld();

  // --- ایجاد Attractor (سیاهچاله) ---
  final attractor = Entity();
  // موقعیت مرکزی برای جاذب
  attractor.add(PositionComponent(x: 200, y: 400, width: 20, height: 20));
  attractor.add(AttractorComponent(strength: 15000));
  attractor
      .add(TagsComponent({'attractor'})); // تگ 'attractor' برای شناسایی در UI
  world.addEntity(attractor);

  // --- ایجاد Spawner ذرات ---
  final spawner = Entity();
  // ذرات از بالای صفحه و مرکز شروع به تولید می‌کنند.
  spawner.add(PositionComponent(x: 200, y: 100));
  spawner.add(SpawnerComponent(spawnRate: 200)); // نرخ تولید ذرات در ثانیه
  world.addEntity(spawner);

  // --- افزودن سیستم‌ها ---
  // سیستم تولید ذرات
  world.addSystem(ParticleSpawningSystem());
  // سیستم فیزیک برای اعمال سرعت به ذرات
  world.addSystem(PhysicsSystem());
  // سیستم چرخه حیات ذرات (برای حذف ذرات پس از اتمام عمرشان)
  world.addSystem(ParticleLifecycleSystem());
  // سیستم جاذبه برای کشیدن ذرات به سمت جاذب
  world.addSystem(AttractionSystem());
  // سیستم اشاره‌گر برای تعامل با UI (مثل حرکت جاذب با لمس)
  world.addSystem(PointerSystem());

  // همچنین یک Entity برای نگهداری تگ 'particle_field' برای ParticlePainter
  // در ایزوله UI نیاز داریم. این Entity صرفاً برای این است که ParticlePainter
  // بتواند به IDهای ذرات دسترسی داشته باشد، نه اینکه خودش رندر شود.
  // این تگ برای `getAllIdsWithTag` در FlutterRenderingSystem استفاده می شود.
  final particleFieldEntity = Entity();
  particleFieldEntity.add(TagsComponent({'particle_field'}));
  particleFieldEntity.add(PositionComponent(
      x: 0,
      y: 0,
      width: 0,
      height: 0)); // موقعیت صفر، چون فقط یک نگهدارنده است.
  world.addEntity(particleFieldEntity);

  return world;
}

void main() {
  // ثبت تمام کامپوننت‌های سریال‌پذیر از فریم‌ورک اصلی.
  // این مرحله برای دی‌سریال‌سازی صحیح RenderPacketها ضروری است.
  registerCoreComponents();
  runApp(const MyApp());
}

/// ویجت اصلی برنامه.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // پیکربندی سیستم رندرینگ Flutter.
    // این سیستم وظیفه دارد داده‌های Entity را از ایزوله پس‌زمینه دریافت کرده
    // و آنها را به ویجت‌های Flutter تبدیل کند.
    final renderingSystem = FlutterRenderingSystem(
      builders: {
        // Builder برای کل شبیه‌سازی ذرات.
        // این یک CustomPaint را برمی‌گرداند که از ParticlePainter برای رندر
        // تمام ذرات فعال استفاده می‌کند.
        'particle_field': (context, id, controller, manager) {
          // دریافت تمام IDهای Entity با تگ 'particle' از کش رندرینگ.
          final particleIds = controller.getAllIdsWithTag('particle');
          return CustomPaint(
            painter: ParticlePainter(
              particleIds: particleIds,
              controller:
                  controller, // ارسال کنترلر برای دسترسی به کامپوننت‌های ذرات
            ),
            child: const SizedBox
                .expand(), // اجازه می‌دهد CustomPaint تمام فضای موجود را پر کند.
          );
        },
        // Builder برای Attractor (سیاهچاله).
        // یک دایره مشکی با سایه بنفش ایجاد می‌کند.
        'attractor': (context, id, controller, manager) {
          final pos = controller.get<PositionComponent>(id);
          if (pos == null)
            return const SizedBox
                .shrink(); // اگر موقعیت وجود ندارد، یک ویجت خالی برمی‌گرداند.
          return Center(
            child: Container(
              width: pos.width,
              height: pos.height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 5)
                ],
              ),
            ),
          );
        }
      },
    );

    // توجه: ما addUiEntity را برای 'particle_field' یا 'attractor' اینجا
    // صدا نمی‌زنیم، زیرا این Entityها در provideCosmicWorld ایجاد شده و
    // از طریق RenderPacketها به FlutterRenderingSystem ارسال می‌شوند.
    // تنها Entityهایی که فقط در UI وجود دارند (نه در World پس‌زمینه)
    // باید با addUiEntity اضافه شوند.

    return MaterialApp(
      debugShowCheckedModeBanner: false, // پنهان کردن بنر debug
      home: Scaffold(
        backgroundColor: const Color(0xFF121212), // رنگ پس‌زمینه تیره
        appBar: AppBar(
          backgroundColor: Colors.black, // رنگ نوار عنوان
          title: const Text('Nexus Cosmic Simulator',
              style: TextStyle(color: Colors.white)), // عنوان برنامه
        ),
        body: NexusWidget(
          worldProvider:
              provideCosmicWorld, // تابعی که NexusWorld را فراهم می‌کند.
          renderingSystem: renderingSystem, // سیستم رندرینگ Flutter
        ),
      ),
    );
  }
}
