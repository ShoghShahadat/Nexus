import 'package:nexus/nexus.dart';
import 'package:example_dashboard/shared/components/tags.dart';

/// Assembler برای ایجاد موجودیت مربوط به هدر داشبورد.
class HeaderAssembler extends EntityAssembler<EntityId> {
  HeaderAssembler(NexusWorld world, EntityId context) : super(world, context);

  @override
  List<Entity> assemble() {
    final headerEntity = Entity()
      ..add(TagsComponent({DashboardTags.header}))
      ..add(ParentComponent(context)); // `context` is the root entity ID

    world.addEntity(headerEntity);
    return [headerEntity];
  }
}
