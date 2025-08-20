import 'package:nexus/nexus.dart';

/// Represents a single timed task to be executed by the TimerSystem.
/// یک وظیفه زمان‌بندی شده را نشان می‌دهد که توسط TimerSystem اجرا می‌شود.
///
/// This is a helper class for the TimerComponent and not a component itself.
/// این یک کلاس کمکی برای TimerComponent است و به خودی خود یک کامپوننت نیست.
class TimerTask with EquatableMixin {
  /// A unique identifier for this task, useful for finding or removing it.
  /// یک شناسه یکتا برای این وظیفه که برای پیدا کردن یا حذف آن مفید است.
  final String id;

  /// The total duration of the timer in seconds.
  /// مدت زمان کل تایمر به ثانیه.
  final double duration;

  /// Whether the timer should restart after completing.
  /// مشخص می‌کند که آیا تایمر پس از اتمام باید دوباره شروع شود یا خیر.
  final bool repeats;

  /// An optional event to be fired on every frame while the timer is active.
  /// یک رویداد اختیاری که در هر فریم تا زمانی که تایمر فعال است، منتشر می‌شود.
  final dynamic onTickEvent;

  /// The event to be fired when the timer completes.
  /// رویدادی که پس از اتمام تایمر منتشر می‌شود.
  final dynamic onCompleteEvent;

  /// The time elapsed since the timer started. Should only be modified by TimerSystem.
  /// زمان سپری شده از شروع تایمر. فقط باید توسط TimerSystem تغییر کند.
  double elapsedTime = 0.0;

  TimerTask({
    required this.id,
    required this.duration,
    required this.onCompleteEvent,
    this.repeats = false,
    this.onTickEvent,
  });

  @override
  List<Object?> get props =>
      [id, duration, repeats, onTickEvent, onCompleteEvent, elapsedTime];
}

/// A logic-only component that holds a list of timed tasks for an entity.
/// یک کامپوننت فقط-منطقی که لیستی از وظایف زمان‌بندی شده را برای یک موجودیت نگهداری می‌کند.
///
/// Use this component to schedule actions that should occur after a delay or
/// on a recurring basis. The `TimerSystem` processes these tasks.
/// از این کامپوننت برای زمان‌بندی کارهایی که باید با تأخیر یا به صورت دوره‌ای
/// انجام شوند، استفاده کنید. `TimerSystem` این وظایف را پردازش می‌کند.
class TimerComponent extends Component {
  final List<TimerTask> tasks;

  TimerComponent(this.tasks);

  // This component uses reference equality.
  // این کامپوننت از برابری بر اساس رفرنس استفاده می‌کند.
  @override
  List<Object?> get props => [tasks];
}
