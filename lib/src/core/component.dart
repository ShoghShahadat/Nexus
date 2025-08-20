import 'package:nexus/src/core/utils/equatable_mixin.dart';

/// The base class for all Components in the Nexus architecture.
///
/// A Component is a container for pure data. It should not contain any logic.
/// Components are attached to Entities to define their properties and state.
///
/// By mixing in [EquatableMixin], all components are required to implement
/// the [props] getter, enabling value-based equality checks which are crucial
/// for performance optimization.
abstract class Component with EquatableMixin {}
