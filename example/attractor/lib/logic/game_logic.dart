import 'dart:async';
import 'dart:math';
import 'package:nexus/nexus.dart';
import '../components/network_components.dart';
import '../network/mock_server.dart';

/// Represents the core game engine that runs on the server.
/// It holds the server's world and all game logic systems.
class GameLogic {
  final NexusWorld world;
  // --- FIX: Changed the map key from int to String to match the component. ---
  // --- اصلاح: کلید نقشه از int به String تغییر کرد تا با کامپوننت مطابقت داشته باشد. ---
  final Map<String, Entity> _players = {}; // Map<SessionID, PlayerEntity>

  GameLogic(NexusWorld Function() worldProvider) : world = worldProvider();

  Future<void> init() async {
    await world.init();
  }

  void update(double dt) {
    world.update(dt);
  }

  List<Entity> get entitiesToSync => world.entities.values
      .where((e) => e.allComponents.any((c) => c is BinaryComponent))
      .toList();

  // --- FIX: Changed sessionId parameter from int to String. ---
  // --- اصلاح: پارامتر sessionId از int به String تغییر کرد. ---
  Entity onPlayerConnected(String sessionId) {
    final playerEntity = _createPlayerEntity(sessionId);
    _players[sessionId] = playerEntity;
    return playerEntity;
  }

  // --- FIX: Changed sessionId parameter from int to String. ---
  // --- اصلاح: پارامتر sessionId از int به String تغییر کرد. ---
  void onPlayerDisconnected(String sessionId) {
    final playerEntity = _players.remove(sessionId);
    if (playerEntity != null) {
      world.removeEntity(playerEntity.id);
    }
  }

  // --- FIX: Changed sessionId parameter from int to String. ---
  // --- اصلاح: پارامتر sessionId از int به String تغییر کرد. ---
  void handlePlayerInput(String sessionId, double dx, double dy) {
    final playerEntity = _players[sessionId];
    if (playerEntity == null) return;

    final health = playerEntity.get<HealthComponent>();
    if ((health?.currentHealth ?? 0) > 0) {
      final vel = playerEntity.get<VelocityComponent>()!;
      vel.x = dx * MockServer.playerMoveSpeed;
      vel.y = dy * MockServer.playerMoveSpeed;
      playerEntity.add(vel);
    }
  }

  // --- FIX: Changed sessionId parameter from int to String. ---
  // --- اصلاح: پارامتر sessionId از int به String تغییر کرد. ---
  Entity _createPlayerEntity(String sessionId) {
    final playerEntity = Entity();
    final screenInfo = world.rootEntity.get<ScreenInfoComponent>();
    final startX = Random().nextDouble() * (screenInfo?.width ?? 800);
    final startY = (screenInfo?.height ?? 600) * 0.8;

    playerEntity.add(PositionComponent(
        x: startX,
        y: startY,
        width: MockServer.playerBaseSize,
        height: MockServer.playerBaseSize));
    playerEntity.add(VelocityComponent());
    playerEntity.add(HealthComponent(maxHealth: 100));
    // --- FIX: The sessionId is now correctly passed as a String. ---
    // --- اصلاح: اکنون sessionId به درستی به عنوان یک String پاس داده می‌شود. ---
    playerEntity.add(PlayerComponent(sessionId: sessionId));
    playerEntity.add(TagsComponent({'player'}));
    playerEntity.add(CollisionComponent(
        tag: 'player',
        radius: MockServer.playerBaseSize / 2,
        collidesWith: {'meteor', 'health_orb'}));
    playerEntity.add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(playerEntity);
    return playerEntity;
  }

  void dispose() {
    world.clear();
    _players.clear();
  }
}
