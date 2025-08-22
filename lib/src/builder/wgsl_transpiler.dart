import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class WgslTranspiler {
  String transpile(MethodDeclaration method) {
    final visitor = _WgslBodyVisitor();
    method.body.accept(visitor);
    return visitor.toString();
  }
}

class _WgslBodyVisitor extends SimpleAstVisitor<void> {
  final StringBuffer _buffer = StringBuffer();

  @override
  String toString() => _buffer.toString();

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    for (final statement in node.block.statements) {
      statement.accept(this);
      _buffer.writeln();
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    _buffer.write('    ${_translateExpression(node.expression)};');
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    final keyword = 'let'; // WGSL uses 'let' for immutable bindings
    final name = node.variables.variables.first.name.lexeme;
    final initializer =
        _translateExpression(node.variables.variables.first.initializer!);
    _buffer.write('    $keyword $name = $initializer;');
  }

  @override
  void visitIfStatement(IfStatement node) {
    _buffer.write('    if (${_translateExpression(node.expression)}) {');
    _buffer.writeln();
    node.thenStatement.accept(this);
    _buffer.writeln();
    _buffer.write('    }');
    if (node.elseStatement != null) {
      _buffer.write(' else {');
      _buffer.writeln();
      node.elseStatement!.accept(this);
      _buffer.writeln();
      _buffer.write('    }');
    }
  }

  String _translateExpression(Expression expression) {
    if (expression is AssignmentExpression) {
      final left = _translateExpression(expression.leftHandSide);
      final right = _translateExpression(expression.rightHandSide);
      return '$left ${expression.operator.lexeme} $right';
    }
    if (expression is BinaryExpression) {
      final left = _translateExpression(expression.leftOperand);
      final right = _translateExpression(expression.rightOperand);
      return '$left ${expression.operator.lexeme} $right';
    }
    if (expression is PrefixedIdentifier) {
      return _mapIdentifier(expression.toSource());
    }
    if (expression is PropertyAccess) {
      return _mapIdentifier(expression.toSource());
    }
    if (expression is MethodInvocation) {
      final methodName = expression.methodName.name;
      final arguments = expression.argumentList.arguments
          .map(_translateExpression)
          .join(', ');

      // --- FIX: Handle top-level function calls like sqrt(), cos(), etc. ---
      if (expression.target == null) {
        // Map common Dart math functions to WGSL built-in functions
        const supportedFunctions = {
          'sqrt',
          'cos',
          'sin',
          'tan',
          'abs',
          'floor',
          'ceil',
          'min',
          'max'
        };
        if (supportedFunctions.contains(methodName)) {
          return '$methodName($arguments)';
        } else {
          return '// Unsupported function: $methodName';
        }
      } else {
        final target = _translateExpression(expression.target!);
        return '$target.$methodName($arguments)';
      }
    }
    if (expression is SimpleIdentifier) {
      return _mapIdentifier(expression.name);
    }
    if (expression is Literal) {
      return expression.toSource();
    }
    if (expression is ParenthesizedExpression) {
      return '(${_translateExpression(expression.expression)})';
    }
    // Fallback for unsupported expressions
    return '// Unsupported: ${expression.runtimeType}';
  }

  String _mapIdentifier(String dartIdentifier) {
    // This is where you map Dart variables/properties to WGSL equivalents.
    return dartIdentifier
        .replaceAll('p.position.x', 'p.pos.x')
        .replaceAll('p.position.y', 'p.pos.y')
        .replaceAll('p.velocity.x', 'p.vel.x')
        .replaceAll('p.velocity.y', 'p.vel.y')
        .replaceAll('p.age', 'p.age')
        .replaceAll('p.maxAge', 'p.max_age')
        .replaceAll('p.initialSize', 'p.initial_size')
        .replaceAll('ctx.deltaTime', 'params.delta_time')
        .replaceAll('ctx.attractorX', 'params.attractor_x')
        .replaceAll('ctx.attractorY', 'params.attractor_y')
        .replaceAll('ctx.attractorStrength', 'params.attractor_strength');
  }
}
