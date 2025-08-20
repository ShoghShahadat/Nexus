import 'package:collection/collection.dart';

/// A mixin that helps implement equality based on a list of properties.
///
/// By using this mixin, classes can override `operator ==` and `hashCode`
/// based on the values of their properties, rather than their instance identity.
/// This is crucial for performance optimizations, as it prevents unnecessary
/// UI rebuilds when component data has not actually changed.
mixin EquatableMixin {
  /// The list of properties that will be used to determine whether
  /// two instances are equal.
  List<Object?> get props;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EquatableMixin &&
            runtimeType == other.runtimeType &&
            const IterableEquality().equals(props, other.props);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^ const DeepCollectionEquality().hash(props);
}
