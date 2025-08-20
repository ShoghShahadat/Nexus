import 'package:nexus/nexus.dart';

/// A specialized logic function to handle the 'warning' tag on an entity.
///
/// This function is a pure piece of logic, decoupled from any specific system.
/// It checks the counter state and adds or removes the 'warning' tag accordingly.
void handleWarningTag(Entity entity, int state) {
  final tags = entity.get<TagsComponent>()!;
  final isWarning = state < 0;
  final wasWarning = tags.hasTag('warning');

  // If the state is negative and it wasn't before, add the warning tag.
  if (isWarning && !wasWarning) {
    tags.add('warning');
    entity.add(tags); // Re-add component to notify listeners of the change.
  }
  // If the state is not negative but it was before, remove the warning tag.
  else if (!isWarning && wasWarning) {
    tags.remove('warning');
    entity.add(tags); // Re-add component to notify listeners of the change.
  }
}
