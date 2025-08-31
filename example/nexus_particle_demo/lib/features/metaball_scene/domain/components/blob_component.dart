import 'package:nexus/nexus.dart';

/// A marker component for a metaball blob.
/// یک کامپوننت نشانگر برای یک قطره متابال.
class BlobComponent extends Component {
  final double radius;

  BlobComponent(this.radius);

  @override
  List<Object?> get props => [radius];
}
