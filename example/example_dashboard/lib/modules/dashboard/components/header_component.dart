import 'package:nexus/nexus.dart';

/// کامپوننت داده برای نگهداری اطلاعات هدر داشبورد.
class HeaderComponent extends Component with SerializableComponent {
  final String title;
  final String userName;

  HeaderComponent({required this.title, required this.userName});

  @override
  List<Object?> get props => [title, userName];

  // --- Serialization ---
  factory HeaderComponent.fromJson(Map<String, dynamic> json) {
    return HeaderComponent(
      title: json['title'] as String,
      userName: json['userName'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'userName': userName,
      };
}
