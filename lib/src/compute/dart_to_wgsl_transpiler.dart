import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// A utility class responsible for transpiling the body of a Dart function
/// into a WGSL (WebGPU Shading Language) compute shader.
class DartToWgslTranspiler {
  final String _dartCode;
  final String _functionName;

  DartToWgslTranspiler({
    required String dartCode,
    required String functionName,
  })  : _dartCode = dartCode,
        _functionName = functionName;

  /// Performs the transpilation and returns the generated WGSL code.
  String transpile() {
    final parseResult = parseString(content: _dartCode);
    final compilationUnit = parseResult.unit;

    FunctionDeclaration? targetFunction;
    try {
      targetFunction = compilationUnit.declarations
          .whereType<FunctionDeclaration>()
          .firstWhere((d) => d.name.lexeme == _functionName);
    } catch (e) {
      throw Exception(
          'Could not find a function named "$_functionName" to transpile.');
    }

    final visitor = _WgslBodyVisitor();
    final body = targetFunction.functionExpression.body;

    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        statement.accept(visitor);
      }
    } else {
      throw Exception(
          'The target function body must be a block body (e.g. enclosed in {}).');
    }

    // In a real implementation, we would analyze the function parameters
    // and component fields to automatically generate these structs.
    // For now, we use a hardcoded header.
    return _generateFullShader(visitor.getWgslBody());
  }

  String _generateFullShader(String body) {
    final header = '''
struct Vec2 {
    x: f32,
    y: f32,
};

struct Particle {
    position: Vec2,
    velocity: Vec2,
};

@group(0) @binding(0)
var<storage, read_write> particles: array<Particle>;

''';
    final mainFunction = '''
@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let index = global_id.x;
    var p = particles[index];
$body
    particles[index] = p;
}
''';

    return header + mainFunction;
  }
}

/// An internal AST Visitor that translates only the body of a function.
class _WgslBodyVisitor extends SimpleAstVisitor<void> {
  final StringBuffer _bodyWgsl = StringBuffer();

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final translatedLine = _translateExpression(node.expression);
    _bodyWgsl.writeln('    $translatedLine;');
  }

  String _translateExpression(Expression expression) {
    if (expression is AssignmentExpression) {
      final left = _translateExpression(expression.leftHandSide);
      final right = _translateExpression(expression.rightHandSide);
      return '$left = $right';
    }
    if (expression is BinaryExpression) {
      final left = _translateExpression(expression.leftOperand);
      final right = _translateExpression(expression.rightOperand);
      final op = expression.operator.lexeme;
      return '$left $op $right';
    }
    if (expression is PrefixedIdentifier || expression is PropertyAccess) {
      return expression.toSource();
    }
    if (expression is DoubleLiteral) {
      return expression.toSource();
    }
    if (expression is IntegerLiteral) {
      return '${expression.toSource()}.0';
    }
    return '// Unsupported: ${expression.runtimeType}';
  }

  String getWgslBody() => _bodyWgsl.toString();
}
