import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/dom_element_component.dart';
import 'package:nexus/src/components/stylesheet_component.dart';

/// The core rendering engine that translates a tree of `DomElementComponent`
/// entities into a Flutter widget tree, applying styles from a `StyleSheetComponent`.
class WebUIBuilder implements IWidgetBuilder {
  /// The tag used to find the root entity of the web UI scene.
  final String rootEntityTag;

  const WebUIBuilder({this.rootEntityTag = 'web_root'});

  @override
  Widget build(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId, // This is the root entity for this build scope.
  ) {
    // Find the global StyleSheetComponent, typically on the root entity.
    final rootEntities = renderingSystem.getAllIdsWithTag('root');
    final styleSheet = rootEntities.isNotEmpty
        ? renderingSystem.get<StyleSheetComponent>(rootEntities.first)
        : null;

    // Use an EntityWidgetBuilder to reactively rebuild the entire tree
    // when the root entity or its stylesheet changes.
    return EntityWidgetBuilder(
      renderingSystem: renderingSystem,
      entityId: entityId,
      builder: (context) {
        return _buildRecursive(context, renderingSystem, entityId, styleSheet);
      },
    );
  }

  /// Recursively builds the widget tree for a given entity.
  Widget _buildRecursive(
    BuildContext context,
    FlutterRenderingSystem renderingSystem,
    EntityId entityId,
    StyleSheetComponent? styleSheet,
  ) {
    final domElement = renderingSystem.get<DomElementComponent>(entityId);
    if (domElement == null) {
      return const SizedBox.shrink(); // Render nothing if component is missing.
    }

    final childrenComp = renderingSystem.get<ChildrenComponent>(entityId);
    final resolvedStyle =
        _resolveStyles(domElement, styleSheet ?? StyleSheetComponent());

    // Recursively build children first.
    final List<Widget> children = childrenComp?.children
            .map((childId) =>
                _buildRecursive(context, renderingSystem, childId, styleSheet))
            .toList() ??
        [];

    // Build the widget for the current element.
    Widget currentWidget;
    switch (domElement.tag.toLowerCase()) {
      case 'p':
      case 'h1':
      case 'h2':
        currentWidget =
            _buildText(domElement, resolvedStyle, domElement.tag.toLowerCase());
        break;
      case 'div':
      default:
        currentWidget = _buildContainer(children, resolvedStyle);
        break;
    }

    // Wrap with padding and margin if they exist.
    return _applyPaddingAndMargin(currentWidget, resolvedStyle);
  }

  /// Resolves the final style for a DomElement by merging styles from tag and class selectors.
  Map<String, dynamic> _resolveStyles(
      DomElementComponent element, StyleSheetComponent styleSheet) {
    final finalStyle = <String, dynamic>{};

    // 1. Apply tag-based styles (lowest precedence).
    final tagStyle = styleSheet.styles[element.tag];
    if (tagStyle != null) {
      finalStyle.addAll(tagStyle);
    }

    // 2. Apply class-based styles (higher precedence, overrides tag styles).
    for (final className in element.classes) {
      final classStyle = styleSheet.styles['.$className'];
      if (classStyle != null) {
        finalStyle.addAll(classStyle);
      }
    }

    return finalStyle;
  }

  /// Builds a Text widget from the element data and styles.
  Widget _buildText(
      DomElementComponent element, Map<String, dynamic> style, String tag) {
    double defaultFontSize = 16.0;
    FontWeight defaultFontWeight = FontWeight.normal;

    switch (tag) {
      case 'h1':
        defaultFontSize = 32.0;
        defaultFontWeight = FontWeight.bold;
        break;
      case 'h2':
        defaultFontSize = 24.0;
        defaultFontWeight = FontWeight.bold;
        break;
    }

    return Text(
      element.text ?? '',
      style: TextStyle(
        color: _parseColor(style['color']),
        fontSize: _parseDouble(style['font-size']) ?? defaultFontSize,
        fontWeight: style['font-weight'] == 'bold'
            ? FontWeight.bold
            : defaultFontWeight,
      ),
    );
  }

  /// Builds a Container widget, handling flexbox properties.
  Widget _buildContainer(List<Widget> children, Map<String, dynamic> style) {
    final isFlex = style['display'] == 'flex';

    if (isFlex) {
      final direction =
          style['flex-direction'] == 'row' ? Axis.horizontal : Axis.vertical;
      return Flex(
        direction: direction,
        mainAxisAlignment: _parseMainAxisAlignment(style['justify-content']),
        crossAxisAlignment: _parseCrossAxisAlignment(style['align-items']),
        children: children,
      );
    } else {
      // If not flex, and has multiple children, wrap in a Column.
      // If one child, it becomes the direct child of the Container.
      return Container(
        color: _parseColor(style['background-color']),
        width: _parseDouble(style['width']),
        height: _parseDouble(style['height']),
        child: children.length == 1
            ? children.first
            : Column(
                // Default to a Column for multiple children in a non-flex div.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
      );
    }
  }

  /// Wraps a widget with Padding and Margin based on resolved styles.
  Widget _applyPaddingAndMargin(Widget child, Map<String, dynamic> style) {
    Widget paddedChild = child;
    final padding = _parseEdgeInsets(style['padding']);
    if (padding != null) {
      paddedChild = Padding(padding: padding, child: paddedChild);
    }
    final margin = _parseEdgeInsets(style['margin']);
    if (margin != null) {
      return Padding(padding: margin, child: paddedChild);
    }
    return paddedChild;
  }

  // --- Style Parsers ---

  Color? _parseColor(dynamic colorValue) {
    if (colorValue is! String || !colorValue.startsWith('#')) return null;
    final hex = colorValue.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove 'px' and parse.
      return double.tryParse(value.replaceAll('px', ''));
    }
    return null;
  }

  EdgeInsets? _parseEdgeInsets(dynamic value) {
    final doubleValue = _parseDouble(value);
    if (doubleValue != null) {
      return EdgeInsets.all(doubleValue);
    }
    return null; // Can be extended to support '10px 20px' etc.
  }

  MainAxisAlignment _parseMainAxisAlignment(String? value) {
    return switch (value) {
      'center' => MainAxisAlignment.center,
      'flex-start' => MainAxisAlignment.start,
      'flex-end' => MainAxisAlignment.end,
      'space-between' => MainAxisAlignment.spaceBetween,
      'space-around' => MainAxisAlignment.spaceAround,
      _ => MainAxisAlignment.start,
    };
  }

  CrossAxisAlignment _parseCrossAxisAlignment(String? value) {
    return switch (value) {
      'center' => CrossAxisAlignment.center,
      'flex-start' => CrossAxisAlignment.start,
      'flex-end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.start,
    };
  }
}
