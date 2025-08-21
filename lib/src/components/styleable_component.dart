import 'package:nexus/nexus.dart';

/// کامپوننتی که به یک موجودیت اجازه می‌دهد تا ظاهر خود را بر اساس تم فعال برنامه تطبیق دهد.
///
/// این کامپوننت تعریف می‌کند که ویژگی‌های بصری یک موجودیت (مانند رنگ پس‌زمینه)
/// به کدام مقادیر از تم کلی برنامه (نگهداری شده در ThemeComponent) متصل شوند.
class StyleableComponent extends Component with SerializableComponent {
  /// نقشه‌ای که ویژگی‌های بصری را به کلیدهای موجود در ThemeComponent متصل می‌کند.
  ///
  /// مثال:
  /// {
  ///   'backgroundColor': 'primaryColor', // رنگ پس‌زمینه این موجودیت، رنگ اصلی تم باشد.
  ///   'shadowColor': 'shadowColor'
  /// }
  final Map<String, String> styleBindings;

  StyleableComponent({this.styleBindings = const {}});

  /// یک کامپوننت را از داده‌های JSON بازسازی می‌کند.
  factory StyleableComponent.fromJson(Map<String, dynamic> json) {
    return StyleableComponent(
      styleBindings: Map<String, String>.from(json['styleBindings']),
    );
  }

  /// این کامپوننت را به یک نقشه JSON تبدیل می‌کند.
  @override
  Map<String, dynamic> toJson() => {
        'styleBindings': styleBindings,
      };

  @override
  List<Object?> get props => [styleBindings];
}
