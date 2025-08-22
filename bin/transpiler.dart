import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

Future<void> main(List<String> arguments) async {
  final inputFile = File('bin/input.dart');
  if (!await inputFile.exists()) {
    print('Error: input.dart not found in bin/ directory.');
    return;
  }

  print('--- Analyzing bin/input.dart ---');
  final content = await inputFile.readAsString();

  final parseResult = parseString(content: content);
  if (parseResult.errors.isNotEmpty) {
    print('--- PARSE ERRORS ---');
    parseResult.errors.forEach(print);
    return;
  }

  final compilationUnit = parseResult.unit;

  final targetFunction = compilationUnit.declarations
      .whereType<FunctionDeclaration>()
      .firstWhere((d) => d.name.lexeme == 'gpuLogic',
          orElse: () => throw Exception('Function "gpuLogic" not found.'));

  final visitor = WgslTranspilerVisitor();
  targetFunction.functionExpression.body.accept(visitor);

  print('\n--- Transpilation Result (WGSL Code) ---');
  print(visitor.getWgslCode());
}

/// An AST Visitor that translates the body of a Dart function into WGSL.
class WgslTranspilerVisitor extends SimpleAstVisitor<void> {
  final StringBuffer _bodyWgsl = StringBuffer();

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    for (final statement in node.block.statements) {
      _bodyWgsl.writeln(_translateStatement(statement));
    }
  }

  String _translateStatement(Statement statement) {
    if (statement is ExpressionStatement) {
      return '    ${_translateExpression(statement.expression)};';
    }
    if (statement is IfStatement) {
      // --- FIX: Use `expression` instead of the deprecated `condition` ---
      // --- اصلاح: استفاده از `expression` به جای `condition` منسوخ شده ---
      final condition = _translateExpression(statement.expression);
      final thenBlock = _translateStatement(statement.thenStatement);
      // Note: Does not handle 'else' for simplicity in this PoC.
      return '    if ($condition) {\n$thenBlock\n    }';
    }
    if (statement is Block) {
      return statement.statements.map(_translateStatement).join('\n');
    }
    if (statement is VariableDeclarationStatement) {
      // --- FIX: Use `variables` instead of the non-existent `declarations` ---
      // --- اصلاح: استفاده از `variables` به جای `declarations` که وجود ندارد ---
      final declaration = statement.variables.variables.first;
      final name = declaration.name.lexeme;
      final value = _translateExpression(declaration.initializer!);
      return '    var $name = $value;';
    }
    return '// Unsupported statement: ${statement.runtimeType}';
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
      return '($left $op $right)';
    }
    if (expression is PrefixedIdentifier || expression is PropertyAccess) {
      return expression.toSource().replaceAll('final ', '');
    }
    if (expression is DoubleLiteral) {
      return expression.toSource();
    }
    if (expression is IntegerLiteral) {
      return '${expression.toSource()}.0';
    }
    // A simple placeholder for function calls. A real transpiler would need
    // to map Dart math functions to WGSL built-in functions (e.g., cos, sin, sqrt).
    if (expression is MethodInvocation) {
      return expression.toSource();
    }
    return '// Unsupported expression: ${expression.runtimeType}';
  }

  String getWgslCode() {
    final header = '''
struct Particle {
    pos: vec2<f32>,
    vel: vec2<f32>,
    age: f32,
    max_age: f32,
    initial_size: f32,
    seed: f32,
};

struct SimParams {
    delta_time: f32,
    attractor_x: f32,
    attractor_y: f32,
    attractor_strength: f32,
};

@group(0) @binding(1)
var<uniform> params: SimParams;

@group(0) @binding(0)
var<storage, read_write> particles: array<Particle>;
''';
    final mainFunction = '''
@compute @workgroup_size(256)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let index = global_id.x;
    if (index >= arrayLength(&particles)) { return; }
    var p = particles[index];

${_bodyWgsl.toString()}
    particles[index] = p;
}
''';
    return '$header\n$mainFunction';
  }
}
