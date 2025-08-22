import 'package:nexus/nexus.dart';
import '../component_registration.dart';
import '../components/network_components.dart';
import '../systems/debug_system.dart';
import '../systems/network_system.dart';
import '../systems/player_control_system.dart';

// --- CLIENT WORLD PROVIDER ---

NexusWorld provideAttractorWorld() {
  registerCoreComponents();
  registerAllComponents();

  final world = NexusWorld();
  final serializer = BinaryWorldSerializer(BinaryComponentFactory.I);

  // --- CRITICAL FIX: Use the base HTTP URL for the Socket.IO client ---
  // The socket_io_client library will handle the path and protocol upgrade automatically.
  // --- اصلاح حیاتی: استفاده از URL پایه HTTP برای کلاینت Socket.IO ---
  // کتابخانه socket_io_client مسیر و ارتقاء پروتکل را به صورت خودکار مدیریت می‌کند.
  const serverUrl = 'http://127.0.0.1:5000';

  world.addSystems([
    ResponsivenessSystem(),
    DebugSystem(),
    NetworkSystem(serializer, serverUrl: serverUrl),
    PlayerControlSystem(), // Corrected typo from previous version
  ]);

  world.rootEntity.addComponents([
    CustomWidgetComponent(widgetType: 'particle_canvas'),
    BlackboardComponent({'score': 0, 'local_player_id': null}),
    NetworkStateComponent(),
  ]);

  return world;
}
