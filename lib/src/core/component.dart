/// The base class for all Components in the Nexus architecture.
///
/// A Component is a container for pure data. It should not contain any logic.
/// Components are attached to Entities to define their properties and state.
///
/// For example, a `PositionComponent` would store x and y coordinates,
/// while a `HealthComponent` would store the current health points.
abstract class Component {}
