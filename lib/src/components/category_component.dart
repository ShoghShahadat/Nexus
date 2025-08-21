import 'package:nexus/nexus.dart';

/// A serializable component that provides structured, multi-dimensional categorization
/// for an entity, offering a more powerful alternative to simple tags.
///
/// Use this component to define an entity's identity within various groups,
/// enabling complex queries and logic.
///
/// Example for a product in a shopping cart:
/// CategoryComponent({
///   'itemGroup': 'shopping_cart',
///   'productType': 'dairy',
///   'brand': 'Pegah'
/// })
class CategoryComponent extends Component with SerializableComponent {
  /// A map where keys represent category types (e.g., 'group', 'type') and
  /// values represent the entity's value within that category.
  final Map<String, dynamic> categories;

  CategoryComponent(this.categories);

  /// Retrieves the value for a specific category type.
  /// Returns null if the category does not exist.
  T? get<T>(String categoryType) {
    final value = categories[categoryType];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Deserializes a component from JSON data.
  factory CategoryComponent.fromJson(Map<String, dynamic> json) {
    return CategoryComponent(
      Map<String, dynamic>.from(json['categories']),
    );
  }

  /// Serializes this component to a JSON map.
  @override
  Map<String, dynamic> toJson() => {'categories': categories};

  @override
  List<Object?> get props => [categories];
}
