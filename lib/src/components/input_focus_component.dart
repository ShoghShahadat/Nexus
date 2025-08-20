import 'package:nexus/nexus.dart';

/// A marker component that indicates an entity can receive keyboard input.
/// یک کامپوننت نشانگر که مشخص می‌کند یک موجودیت می‌تواند ورودی کیبورد دریافت کند.
///
/// The `AdvancedInputSystem` will direct `KeyEvent`s to the entity that
/// currently has this component. Only one entity should have this component
/// at any given time to avoid ambiguity.
/// سیستم `AdvancedInputSystem` رویدادهای `KeyEvent` را به موجودیتی که این
/// کامپوننت را دارد، هدایت می‌کند. برای جلوگیری از ابهام، در هر زمان فقط
/// یک موجودیت باید این کامپوننت را داشته باشد.
class InputFocusComponent extends Component with SerializableComponent {
  InputFocusComponent();

  factory InputFocusComponent.fromJson(Map<String, dynamic> json) {
    return InputFocusComponent();
  }

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}
