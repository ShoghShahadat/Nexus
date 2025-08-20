/// The main library for the Nexus Router adapter package.
///
/// This library provides the integration layer between the Nexus ECS framework
/// and the go_router package, enabling scene-based navigation.
library nexus_router;

// Exporting the core class that bridges the two packages.
export '../src/routing/nexus_route.dart';

// Also, re-exporting the core Nexus and GoRouter libraries for convenience,
// so the developer only needs one import in their routing file.
export 'package:nexus/nexus.dart';
export 'package:go_router/go_router.dart';
