import 'package:nexus/src/core/entity.dart';

/// Defines a standard signature for a reusable, self-contained piece of logic
/// that operates on an entity.
///
/// By defining logic in functions with this signature, systems can become
/// simple coordinators that delegate their work to a collection of these

/// highly-testable and reusable logic functions.
///
/// [E] is the type of the entity.
/// [C] is the type of the context or state needed by the logic.
/// [R] is the return type of the function, which can be void if it
/// only produces side effects.
typedef LogicFunction<E extends Entity, C, R> = R Function(E entity, C context);
