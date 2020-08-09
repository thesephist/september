std := load('../vendor/std')

log := std.log
f := std.format
map := std.map
cat := std.cat

str := load('../vendor/str')

replace := str.replace

Tokenize := load('tokenize')
Tok := Tokenize.Tok

Parse := load('parse')
Node := Parse.Node

render := node => node.type :: {
	(Node.FnCall) -> renderFnCall(node)

	(Node.UnaryExpr) -> renderUnaryExpr(node)
	(Node.BinaryExpr) -> renderBinaryExpr(node)

	(Node.NumberLiteral) -> renderNumberLiteral(node)
	(Node.StringLiteral) -> renderStringLiteral(node)
	(Node.BooleanLiteral) -> renderBooleanLiteral(node)
	(Node.FnLiteral) -> renderFnLiteral(node)

	(Node.ListLiteral) -> renderListLiteral(node)
	(Node.ObjectLiteral) -> renderObjectLiteral(node)

	(Node.Ident) -> renderIdent(node)
	(Node.EmptyIdent) -> 'null'

	(Node.ExprList) -> renderExprList(node)
	(Node.MatchExpr) -> renderMatchExpr(node)

	_ -> '(( "not implemented" ))'
}

renderErr := msg => f('throw new Error("{{0}}")', [msg])

renderNumberLiteral := node => string(node.val)
renderStringLiteral := node => '`' + replace(node.val, '`', '\\`') + '`'
renderBooleanLiteral := node => string(node.val)

renderListLiteral := node => '[' + cat(map(node.exprs, render), ', ') + ']'

renderObjectEntry := node => f('{{0}}: {{1}}', [
	render(node.key)
	render(node.val)
])
renderObjectLiteral := node => '{' + cat(map(node.entries, renderObjectEntry), ', ') + '}'

renderFnArg := (node, i) => node.type :: {
	(Node.EmptyIdent) -> '__' + string(i) `` avoid duplicate arg names
	(Node.Ident) -> renderIdent(node)
	_ -> '__' + string(i)
}

renderFnLiteral := node => f('({{0}}) => {{1}}', [
	cat(map(node.args, renderFnArg), ', ')
	render(node.body)
])

renderFnCall := node => f(
	'{{0}}({{1}})'
	[
		render(node.fn)
		cat(map(node.args, render), ', ')
	]
)

renderUnaryExpr := node => node.op :: {
	(Tok.NegOp) -> f('__ink_negate({{ 0 }})', [render(node.left)])
	_ -> renderErr(f('UnaryExpr with unknown op: {{0}}', [node.op]))
}

renderBinaryExpr := node => node.op :: {
	(Tok.AddOp) -> f('{{0}} + {{1}}', [render(node.left), render(node.right)])
	(Tok.SubOp) -> f('{{0}} - {{1}}', [render(node.left), render(node.right)])
	(Tok.MulOp) -> f('{{0}} * {{1}}', [render(node.left), render(node.right)])
	(Tok.DivOp) -> f('{{0}} / {{1}}', [render(node.left), render(node.right)])
	(Tok.ModOp) -> f('{{0}} % {{1}}', [render(node.left), render(node.right)])

	(Tok.AndOp) -> f('__ink_and({{0}}, {{1}})', [render(node.left), render(node.right)])
	(Tok.XorOp) -> f('__ink_xor({{0}}, {{1}})', [render(node.left), render(node.right)])
	(Tok.OrOp) -> f('__ink_or({{0}}, {{1}})', [render(node.left), render(node.right)])

	(Tok.EqOp) -> f('__ink_eq({{0}}, {{1}})', [render(node.left), render(node.right)])
	(Tok.GtOp) -> f('{{0}} > {{1}}', [render(node.left), render(node.right)])
	(Tok.LtOp) -> f('{{0}} < {{1}}', [render(node.left), render(node.right)])

	(Tok.AccessorOp) -> node.right.type :: {
		(Node.Ident) -> f('({{0}}.{{1}})', [render(node.left), render(node.right)])
		_ -> f('({{0}}[{{1}}])', [render(node.left), render(node.right)])
	}

	_ -> renderErr(f('BinaryExpr with unknown op: {{0}}', [node.op]))
}

renderIdent := node => node.val

renderExprList := node => '(' + cat(map(node.exprs, render), ', ') + ')'

renderMatchExpr := node => f('__ink_match({{0}}, [{{1}}])', [
	render(node.condition)
	cat(map(node.clauses, renderMatchClause), ', ')
])

renderMatchClause := node => f('[{{0}}, () => {{1}}]', [
	render(node.target)
	render(node.expr)
])
