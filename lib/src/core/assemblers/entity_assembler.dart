import 'package:nexus/src/core/entity.dart';
import 'package:nexus/src/core/nexus_world.dart';

/// The base class for an Entity Assembler.
///
/// An assembler is responsible for the concrete logic of creating and
/// configuring entities. By separating this logic from the EntityProvider,
/// the codebase becomes more organized, scalable, and easier to maintain,
/// especially in large projects with many types of entities.
///
/// Developers should extend this class to create specialized assemblers
/// for different features or modules.
abstract class EntityAssembler<T> {
  final NexusWorld world;
  final T context;

  /// Creates an assembler with the necessary world and an optional context.
  ///
  /// The [context] can be any object (like a Cubit, a repository, or a data
  /// class) that provides necessary data or dependencies for entity creation.
  EntityAssembler(this.world, this.context);

  /// A method that should be implemented to create a list of all entities
  /// managed by this assembler.
  List<Entity> assemble();
}
