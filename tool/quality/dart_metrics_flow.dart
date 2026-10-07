import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

final class FlowMetricsVisitor extends RecursiveAstVisitor<void> {
  int complexity = 1;
  int maxDepth = 0;
  int _depth = 0;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.lexeme == '&&' || node.operator.lexeme == '||') {
      complexity += 1;
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    complexity += 1;
    _nested(() => super.visitCatchClause(node));
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    complexity += 1;
    super.visitConditionalExpression(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {}

  @override
  void visitDoStatement(DoStatement node) {
    complexity += 1;
    _nested(() => super.visitDoStatement(node));
  }

  @override
  void visitForElement(ForElement node) {
    complexity += 1;
    _nested(() => super.visitForElement(node));
  }

  @override
  void visitForStatement(ForStatement node) {
    complexity += 1;
    _nested(() => super.visitForStatement(node));
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitIfElement(IfElement node) {
    complexity += 1;
    if (_isElseIfElement(node)) {
      super.visitIfElement(node);
    } else {
      _nested(() => super.visitIfElement(node));
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    complexity += 1;
    final parent = node.parent;
    final isElseIf =
        parent is IfStatement && identical(parent.elseStatement, node);
    if (isElseIf) {
      super.visitIfStatement(node);
    } else {
      _nested(() => super.visitIfStatement(node));
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {}

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {}

  @override
  void visitSwitchCase(SwitchCase node) {
    complexity += 1;
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _nested(() => super.visitSwitchExpression(node));
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    complexity += 1;
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    complexity += 1;
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _nested(() => super.visitSwitchStatement(node));
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    complexity += 1;
    _nested(() => super.visitWhileStatement(node));
  }

  bool _isElseIfElement(IfElement node) {
    final parent = node.parent;
    if (parent is! IfElement) return false;
    // The stable replacement is still experimental in analyzer 14.5.0.
    // ignore: deprecated_member_use
    return identical(parent.elseElement, node);
  }

  void _nested(void Function() visitChildren) {
    _depth += 1;
    if (_depth > maxDepth) maxDepth = _depth;
    visitChildren();
    _depth -= 1;
  }
}
