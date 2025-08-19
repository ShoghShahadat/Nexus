import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

/// A simple Cubit that manages an integer state.
///
/// This represents the "Business Logic" part of our application.
/// It has no knowledge of Flutter or the Nexus architecture. It's pure Dart.
class CounterCubit extends Cubit<int> {
  /// Creates a new CounterCubit with an initial state of 0.
  CounterCubit() : super(0) {
    debugPrint('[CounterCubit] Created with initial state: 0');
  }

  @override
  void emit(int state) {
    debugPrint('[CounterCubit] Emitting new state: $state');
    super.emit(state);
  }

  /// Increments the current state by 1.
  void increment() {
    debugPrint('[CounterCubit] increment() called.');
    emit(state + 1);
  }

  /// Decrements the current state by 1.
  void decrement() {
    debugPrint('[CounterCubit] decrement() called.');
    emit(state - 1);
  }
}
