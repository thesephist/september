std := load('../vendor/std')

log := std.log
f := std.format
clone := std.clone
map := std.map
cat := std.cat

str := load('../vendor/str')

replace := str.replace

Tokenize := load('tokenize')
Tok := Tokenize.Tok

Parse := load('parse')
Node := Parse.Node
ndString := Parse.ndString

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
	(Node.EmptyIdent) -> renderEmpty()

	(Node.ExprList) -> renderExprList(node)
	(Node.MatchExpr) -> renderMatchExpr(node)

	_ -> 'throw new Error("not implemented!")'
}

renderErr := msg => f('throw new Error("{{0}}")', [msg])

renderEmpty := () => '__Ink_Empty'

renderNumberLiteral := node => string(node.val)
renderStringLiteral := node => f('__Ink_String(`{{0}}`)'
	[replace(node.val, '`', '\\`')])
renderBooleanLiteral := node => string(node.val)

renderListLiteral := node => '[' + cat(map(node.exprs, render), ', ') + ']'

renderObjectEntry := node => f('{{0}}: {{1}}', [
	node.key.type :: {
		(Node.Ident) -> render(node.key)
		(Node.EmptyIdent) -> render(node.key)
		(Node.NumberLiteral) -> render(node.key)
		_ -> '[' + render(node.key) + ']'
	}
	render(node.val)
])
renderObjectLiteral := node => '{' + cat(map(node.entries, renderObjectEntry), ', ') + '}'

` some expressions (like assignments to variables ) are expressions in Ink
	but statements in JS, and cannot be returned. This helper fn adds a workaround
	so that we can "return assignments" by returning a reference to the assigned variable. `
renderAsReturn := node => [node.type, node.op, node.left] :: {
	[
		Node.BinaryExpr
		Tok.DefineOp
		{type: Node.Ident, val: _}
	] -> f('{{0}}; return {{1}}', [render(node), render(node.left)])
	_ -> f('return {{0}}', [render(node)])
}

renderFnArg := (node, i) => node.type :: {
	(Node.EmptyIdent) -> '__' + string(i) `` avoid duplicate arg names
	(Node.Ident) -> renderIdent(node)
	_ -> '__' + string(i)
}

renderFnLiteral := node => f('({{0}}) => {{1}}', [
	cat(map(node.args, renderFnArg), ', ')
	node.body.type :: {
		(Node.ObjectLiteral) -> '(' + render(node.body) + ')'
		(Node.ExprList) -> render(node.body)
		_ -> '{' + renderAsReturn(node.body) + '}'
	}
])

renderFnCall := node => f(
	'{{0}}({{1}})'
	[
		node.fn.type :: {
			(Node.Ident) -> node.fn.val :: {
				'in' -> '__ink_in'
				'delete' -> '__ink_delete'
				_ -> render(node.fn)
			}
			_ -> render(node.fn)
		}
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

	(Tok.DefineOp) -> node.decl? :: {
		true -> f('let {{0}} = {{1}}', [render(node.left), render(node.right)])
		_ -> [node.left.type, node.left.op] :: {
			` DefineOp on a property `
			[Node.BinaryExpr, Tok.AccessorOp] -> (
				tmpDfn := clone(node.left)
				tmpDfn.left := {
					type: Node.Ident
					val: '__ink_assgn_trgt'
				}
				f(
					cat([
						'(() => {let __ink_assgn_trgt = __as_ink_string({{0}})'
						'__is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign({{3}}, {{2}}) : {{1}} = {{2}}'
						'return __ink_assgn_trgt})()'
					], '; ')
					[
						render(node.left.left)

						` composite assignment `
						renderDefineTarget(tmpDfn)
						render(node.right)

						` string assignment `
						render(node.left.right)
					]
				)
			)
			_ -> f('{{0}} = {{1}}', [renderDefineTarget(node.left), render(node.right)])
		}
	}

	(Tok.AccessorOp) -> node.right.type :: {
		(Node.Ident) -> f(
			cat([
				'(() => {let __ink_acc_trgt = __as_ink_string({{0}})'
				'return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[{{1}}] || null : (__ink_acc_trgt.{{1}} !== undefined ? __ink_acc_trgt.{{1}} : null)'
				'})()'
			], '; ')
			[render(node.left), render(node.right)]
		)
		_ -> f(
			cat([
				'(() => {let __ink_acc_trgt = __as_ink_string({{0}})'
				'return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[{{1}}] || null : (__ink_acc_trgt[{{1}}] !== undefined ? __ink_acc_trgt[{{1}}] : null)'
				'})()'
			], '; ')
			[render(node.left), render(node.right)]
		)
	}

	_ -> renderErr(f('BinaryExpr with unknown op: {{0}}', [node.op]))
}

renderDefineTarget := node => node.type :: {
	(Node.BinaryExpr) -> node.right.type :: {
		(Node.Ident) -> f('({{0}}.{{1}})', [render(node.left), render(node.right)])
		_ -> f('({{0}}[{{1}}])', [render(node.left), render(node.right)])
	}
	_ -> render(node)
}

renderIdent := node => node.val :: {
	` avoid JavaScript reserved words `
	'break' -> '__ink_ident_break'
	'case' -> '__ink_ident_case'
	'catch' -> '__ink_ident_catch'
	'class' -> '__ink_ident_class'
	'const' -> '__ink_ident_const'
	'continue' -> '__ink_ident_continue'
	'debugger' -> '__ink_ident_debugger'
	'default' -> '__ink_ident_default'
	'delete' -> '__ink_ident_delete'
	'do' -> '__ink_ident_do'
	'else' -> '__ink_ident_else'
	'export' -> '__ink_ident_export'
	'extends' -> '__ink_ident_extends'
	'finally' -> '__ink_ident_finally'
	'for' -> '__ink_ident_for'
	'function' -> '__ink_ident_function'
	'if' -> '__ink_ident_if'
	'import' -> '__ink_ident_import'
	'in' -> '__ink_ident_in'
	'instanceof' -> '__ink_ident_instanceof'
	'new' -> '__ink_ident_new'
	'return' -> '__ink_ident_return'
	'super' -> '__ink_ident_super'
	'switch' -> '__ink_ident_switch'
	'this' -> '__ink_ident_this'
	'throw' -> '__ink_ident_throw'
	'try' -> '__ink_ident_try'
	'typeof' -> '__ink_ident_typeof'
	'var' -> '__ink_ident_var'
	'void' -> '__ink_ident_void'
	'while' -> '__ink_ident_while'
	'with' -> '__ink_ident_with'
	'yield' -> '__ink_ident_yield'
	_ -> (
		ident := replace(node.val, '?', '__ink_qm__')
		ident := replace(ident, '!', '__ink_em__')
		replace(ident, '@', '__ink_am__')
	)
}

renderExprList := node => node.exprs :: {
	[] -> 'null'
	_ -> '(() => {' + cat(map(node.exprs, (expr, i) => (
		i + 1 :: {
			len(node.exprs) -> renderAsReturn(expr)
			_ -> render(expr)
		}
	)), '; ') + '})()'
}

renderMatchExpr := node => f('__ink_match({{0}}, [{{1}}])', [
	render(node.condition)
	cat(map(node.clauses, renderMatchClause), ', ')
])

renderMatchClause := node => f('[() => {{0}}, () => {{1}}]', [
	render(node.target)
	render(node.expr)
])
