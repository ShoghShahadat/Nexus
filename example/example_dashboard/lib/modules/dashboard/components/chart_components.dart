import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';

// --- Sales Chart ---

// FIX: Changed 'extends' to 'with' for EquatableMixin.
// Mixins must be applied with the 'with' keyword.
// اصلاح: کلمه 'extends' به 'with' برای EquatableMixin تغییر کرد.
// Mixinها باید با کلمه کلیدی 'with' اعمال شوند.
class Spot with EquatableMixin {
  final double x;
  final double y;
  const Spot(this.x, this.y);
  @override
  List<Object?> get props => [x, y];
}

class SalesDataComponent extends Component with SerializableComponent {
  final List<Spot> spots;
  SalesDataComponent({required this.spots});

  @override
  Map<String, dynamic> toJson() => {
        'spots': spots.map((s) => {'x': s.x, 'y': s.y}).toList(),
      };

  factory SalesDataComponent.fromJson(Map<String, dynamic> json) =>
      SalesDataComponent(
        spots: (json['spots'] as List)
            .map((s) =>
                Spot((s['x'] as num).toDouble(), (s['y'] as num).toDouble()))
            .toList(),
      );

  @override
  List<Object?> get props => [const DeepCollectionEquality().hash(spots)];
}

// --- User Activity Chart ---

// FIX: Changed 'extends' to 'with' for EquatableMixin.
// Mixins must be applied with the 'with' keyword.
// اصلاح: کلمه 'extends' به 'with' برای EquatableMixin تغییر کرد.
// Mixinها باید با کلمه کلیدی 'with' اعمال شوند.
class Bar with EquatableMixin {
  final double x;
  final double y;
  final String label;
  const Bar(this.x, this.y, this.label);
  @override
  List<Object?> get props => [x, y, label];
}

class UserActivityDataComponent extends Component with SerializableComponent {
  final List<Bar> bars;
  UserActivityDataComponent({required this.bars});

  @override
  Map<String, dynamic> toJson() => {
        'bars':
            bars.map((b) => {'x': b.x, 'y': b.y, 'label': b.label}).toList(),
      };

  factory UserActivityDataComponent.fromJson(Map<String, dynamic> json) =>
      UserActivityDataComponent(
        bars: (json['bars'] as List)
            .map((b) => Bar((b['x'] as num).toDouble(),
                (b['y'] as num).toDouble(), b['label'] as String))
            .toList(),
      );

  @override
  List<Object?> get props => [const DeepCollectionEquality().hash(bars)];
}
