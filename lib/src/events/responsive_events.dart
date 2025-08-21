import 'package:nexus/src/components/screen_info_component.dart';

/// An event fired from the UI thread to the logic isolate whenever the
/// screen or window size changes.
class ScreenResizedEvent {
  final double newWidth;
  final double newHeight;
  final ScreenOrientation newOrientation;

  ScreenResizedEvent({
    required this.newWidth,
    required this.newHeight,
    required this.newOrientation,
  });
}
