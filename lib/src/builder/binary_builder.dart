import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:nexus/src/core/serialization/net_component.dart';

/// A generator that creates binary serialization logic for components
/// annotated with `@NetComponent`.
class BinaryGenerator extends GeneratorForAnnotation<NetComponent> {
  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@NetComponent` can only be used on classes.',
        element: element,
      );
    }

    final className = element.name;
    // Get the name of the file that contains the annotation.
    final hostFileName = element.source.uri.pathSegments.last;
    final fields = element.fields
        .where((f) =>
            !f.isStatic && f.isFinal && f.enclosingElement.name == element.name)
        .toList();

    final buffer = StringBuffer();

    // CRITICAL FIX: Add the 'part of' directive.
    buffer.writeln('part of \'$hostFileName\';');
    buffer.writeln();

    // 1. Generate the `toBinary` extension method
    buffer.writeln('extension _\$${className}Binary on $className {');
    final typeId = annotation.read('typeId').intValue;
    buffer.writeln('  void toBinary(BinaryWriter writer) {');
    buffer
        .writeln('    writer.writeInt32($typeId); // Write component type ID');
    for (final field in fields) {
      _writeFieldSerialization(buffer, field);
    }
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    // 2. Generate the `fromBinary` top-level function
    buffer
        .writeln('$className _\$${className}FromBinary(BinaryReader reader) {');
    buffer.writeln('  return $className(');
    for (final field in fields) {
      _writeFieldDeserialization(buffer, field);
    }
    buffer.writeln('  );');
    buffer.writeln('}');

    return buffer.toString();
  }

  void _writeFieldSerialization(StringBuffer buffer, FieldElement field) {
    final fieldName = field.name;
    final fieldType = field.type.getDisplayString(withNullability: false);

    switch (fieldType) {
      case 'double':
        buffer.writeln('    writer.writeDouble($fieldName);');
        break;
      case 'int':
        buffer.writeln('    writer.writeInt32($fieldName);');
        break;
      case 'bool':
        buffer.writeln('    writer.writeBool($fieldName);');
        break;
      case 'String':
        buffer.writeln('    writer.writeString($fieldName);');
        break;
      default:
        buffer.writeln(
            '    // Field type $fieldType on field $fieldName is not supported for binary serialization.');
    }
  }

  void _writeFieldDeserialization(StringBuffer buffer, FieldElement field) {
    final fieldName = field.name;
    final fieldType = field.type.getDisplayString(withNullability: false);

    buffer.write('    $fieldName: ');
    switch (fieldType) {
      case 'double':
        buffer.writeln('reader.readDouble(),');
        break;
      case 'int':
        buffer.writeln('reader.readInt32(),');
        break;
      case 'bool':
        buffer.writeln('reader.readBool(),');
        break;
      case 'String':
        buffer.writeln('reader.readString(),');
        break;
      default:
        buffer.writeln(
            'throw UnimplementedError("Deserialization for type $fieldType not supported."),');
    }
  }
}
