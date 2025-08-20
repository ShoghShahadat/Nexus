import 'package:nexus/nexus.dart';
import 'package:nexus_example/counter_cubit.dart';
import 'package:nexus_example/counter_module/assemblers/entity_assembler.dart';

/// Provides all entities related to the counter feature using the official
/// EntityAssembler pattern.
///
/// This provider's responsibility is now minimal: it instantiates the
/// correct assembler and uses it to populate the world. This demonstrates
/// the clean separation of concerns promoted by the Nexus framework.
class CounterEntityProvider extends EntityProvider {
  @override
  void createEntities(NexusWorld world) {
    final counterCubit = world.services.get<CounterCubit>();

    // Instantiate the assembler.
    final assembler = CounterEntityAssembler(world, counterCubit);

    // Use the assembler to create and add all its entities to the world.
    for (final entity in assembler.assemble()) {
      world.addEntity(entity);
    }
  }
}
