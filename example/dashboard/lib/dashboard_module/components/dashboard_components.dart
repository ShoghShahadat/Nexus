import 'package:nexus/nexus.dart';

// این فایل شامل تمام کامپوننت‌های داده‌ای سفارشی است که برای ماژول داشبورد نیاز داریم.
// هر کامپوننت، بخشی از داده‌های خالص و سریال‌پذیر را برای یک نوع خاص از Entity تعریف می‌کند.

/// کامپوننت برای نگهداری داده‌های یک کارت خلاصه در بالای داشبورد.
class SummaryCardComponent extends Component with SerializableComponent {
  final String title;
  final String value;
  final int iconCodePoint; // کد پوینت آیکون از مجموعه MaterialIcons
  final int colorValue; // مقدار رنگ به صورت int

  SummaryCardComponent({
    required this.title,
    required this.value,
    required this.iconCodePoint,
    required this.colorValue,
  });

  factory SummaryCardComponent.fromJson(Map<String, dynamic> json) {
    return SummaryCardComponent(
      title: json['title'] as String,
      value: json['value'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
      };

  @override
  List<Object?> get props => [title, value, iconCodePoint, colorValue];
}

/// کامپوننت برای نگهداری داده‌های نمودار میله‌ای.
class ChartDataComponent extends Component with SerializableComponent {
  final String title;
  final List<double> weeklyData; // لیستی از ۷ مقدار برای روزهای هفته

  ChartDataComponent({required this.title, required this.weeklyData});

  factory ChartDataComponent.fromJson(Map<String, dynamic> json) {
    return ChartDataComponent(
      title: json['title'] as String,
      weeklyData: (json['weeklyData'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'weeklyData': weeklyData,
      };

  @override
  List<Object?> get props => [title, weeklyData];
}

/// کامپوننت برای نگهداری داده‌های یک آیتم در لیست وظایف.
class TaskItemComponent extends Component with SerializableComponent {
  final String title;
  final String assignedTo;
  final String priority; // مثلا "High", "Medium", "Low"
  final bool isCompleted;

  TaskItemComponent({
    required this.title,
    required this.assignedTo,
    required this.priority,
    required this.isCompleted,
  });

  factory TaskItemComponent.fromJson(Map<String, dynamic> json) {
    return TaskItemComponent(
      title: json['title'] as String,
      assignedTo: json['assignedTo'] as String,
      priority: json['priority'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'assignedTo': assignedTo,
        'priority': priority,
        'isCompleted': isCompleted,
      };

  @override
  List<Object?> get props => [title, assignedTo, priority, isCompleted];
}

/// یک کامپوننت انیمیشن ساده برای مدیریت حالت‌های ورود (fade-in, slide-in).
class EntryAnimationComponent extends Component with SerializableComponent {
  final double delay; // تاخیر قبل از شروع انیمیشن به ثانیه

  EntryAnimationComponent({required this.delay});

  factory EntryAnimationComponent.fromJson(Map<String, dynamic> json) {
    return EntryAnimationComponent(
      delay: (json['delay'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'delay': delay};

  @override
  List<Object?> get props => [delay];
}
