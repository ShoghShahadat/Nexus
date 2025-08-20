import 'package:nexus/nexus.dart';

/// A serializable component that holds the current state of keyboard input
/// for an entity.
/// یک کامپوننت سریالایزبل که وضعیت فعلی ورودی کیبورد را برای یک موجودیت نگهداری می‌کند.
///
/// This component is managed by the `AdvancedInputSystem` and provides a snapshot
/// of which keys are currently held down.
/// این کامپوننت توسط `AdvancedInputSystem` مدیریت می‌شود و یک تصویر لحظه‌ای از
/// کلیدهایی که در حال حاضر فشرده شده‌اند، ارائه می‌دهد.
class KeyboardInputComponent extends Component with SerializableComponent {
  /// A set of logical key IDs for keys that are currently pressed down.
  /// مجموعه‌ای از شناسه‌های منطقی کلیدهایی که در حال حاضر فشرده شده‌اند.
  final Set<int> keysDown;

  /// The most recent character typed.
  /// آخرین کاراکتر تایپ شده.
  final String? lastCharacter;

  KeyboardInputComponent({
    Set<int>? keysDown,
    this.lastCharacter,
  }) : keysDown = keysDown ?? {};

  factory KeyboardInputComponent.fromJson(Map<String, dynamic> json) {
    return KeyboardInputComponent(
      keysDown: (json['keysDown'] as List).cast<int>().toSet(),
      lastCharacter: json['lastCharacter'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'keysDown': keysDown.toList(),
        'lastCharacter': lastCharacter,
      };

  @override
  List<Object?> get props => [keysDown, lastCharacter];
}
