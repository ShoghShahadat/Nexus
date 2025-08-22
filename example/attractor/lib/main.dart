import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nexus/nexus.dart';
import 'components/debug_info_component.dart';
import 'components/network_components.dart';
import 'events.dart';
import 'network/i_web_socket_client.dart';
// --- MODIFIED: Import the new adapter with the correct class name ---
// --- ویرایش: ایمپورت آداپتور جدید با نام کلاس صحیح ---
import 'network/socket_io_client_adapter.dart';
import 'particle_painter.dart';
import 'widgets/joystick.dart';
import 'world/world_provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// --- Isolate Initializer Function ---
Future<void> isolateInitializer() async {
  // --- MODIFIED: Register the correctly named SocketIOClientAdapter ---
  // --- ویرایش: ثبت SocketIOClientAdapter با نام صحیح ---
  GetIt.I.registerSingleton<IWebSocketClient>(SocketIOClientAdapter());
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FlutterRenderingSystem renderingSystem;

  @override
  void initState() {
    super.initState();
    renderingSystem = FlutterRenderingSystem(
      builders: {
        'particle_canvas': (context, id, controller, manager, child) {
          final rootId = controller.getAllIdsWithTag('root').firstOrNull;
          if (rootId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final networkState = controller.get<NetworkStateComponent>(rootId);
          final blackboard = controller.get<BlackboardComponent>(rootId);
          final localPlayerId = blackboard?.get<EntityId>('local_player_id');

          final allPlayerIds = controller.getAllIdsWithTag('player');
          final meteorIds = controller.getAllIdsWithTag('meteor');
          final healthOrbIds = controller.getAllIdsWithTag('health_orb');

          final debugInfo = controller.get<DebugInfoComponent>(rootId);
          final localPlayerHealth = localPlayerId != null
              ? controller.get<HealthComponent>(localPlayerId)
              : null;
          final isGameOver =
              localPlayerHealth != null && localPlayerHealth.currentHealth <= 0;

          final isTouchDevice = kIsWeb ||
              defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS;

          return Column(
            children: [
              if (networkState != null && !networkState.isConnected)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade900,
                  child: Center(
                    child: Text(
                      networkState.statusMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ParticlePainter(
                          allPlayerIds: allPlayerIds,
                          meteorIds: meteorIds,
                          healthOrbIds: healthOrbIds,
                          localPlayerId: localPlayerId,
                          controller: controller,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    if (isGameOver && localPlayerId != null)
                      const Center(
                        child: _GameOverMessage(),
                      ),
                    if (isTouchDevice)
                      Positioned(
                        bottom: 40,
                        left: 40,
                        child: Joystick(
                          onChanged: (vector) {
                            manager.send(JoystickUpdateEvent(vector));
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (debugInfo != null) _DebugInfoBar(debugInfo: debugInfo),
              if (localPlayerHealth != null)
                _HealthBar(health: localPlayerHealth),
            ],
          );
        },
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          title: const Text('Nexus Attractor: Multiplayer (Socket.IO)'),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: NexusWidget(
          worldProvider: provideAttractorWorld,
          renderingSystem: renderingSystem,
          isolateInitializer: isolateInitializer,
        ),
      ),
    );
  }
}

// UI Helper Widgets (unchanged)
class _GameOverMessage extends StatelessWidget {
  const _GameOverMessage();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16)),
      child: const Text('GAME OVER\nWaiting for next round...',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.redAccent,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.health});
  final HealthComponent health;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: LinearProgressIndicator(
        value: (health.currentHealth / health.maxHealth).clamp(0.0, 1.0),
        backgroundColor: Colors.grey.shade700,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
        minHeight: 10,
      ),
    );
  }
}

class _DebugInfoBar extends StatelessWidget {
  const _DebugInfoBar({required this.debugInfo});
  final DebugInfoComponent debugInfo;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DebugStat(label: 'FPS', value: debugInfo.fps.toStringAsFixed(1)),
          _DebugStat(
              label: 'Frame',
              value: '${debugInfo.frameTime.toStringAsFixed(2)} ms'),
          _DebugStat(
              label: 'Entities', value: debugInfo.entityCount.toString()),
          const _DebugStat(
              label: 'Mode', value: 'Online', valueColor: Colors.cyanAccent),
        ],
      ),
    );
  }
}

class _DebugStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _DebugStat(
      {required this.label,
      required this.value,
      this.valueColor = Colors.white});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              color: valueColor, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
