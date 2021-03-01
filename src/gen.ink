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
ident? := Parse.ident?
ndString := Parse.ndString

gen := node => node.type :: {
	(Node.FnCall) -> genFnCall(node)

	(Node.UnaryExpr) -> genUnaryExpr(node)
	(Node.BinaryExpr) -> genBinaryExpr(node)

	(Node.NumberLiteral) -> genNumberLiteral(node)
	(Node.StringLiteral) -> genStringLiteral(node)
	(Node.BooleanLiteral) -> genBooleanLiteral(node)
	(Node.FnLiteral) -> genFnLiteral(node)

	(Node.ListLiteral) -> genListLiteral(node)
	(Node.ObjectLiteral) -> genObjectLiteral(node)

	(Node.Ident) -> genIdent(node)
	(Node.EmptyIdent) -> genEmpty()

	(Node.ExprList) -> genExprList(node)
	(Node.MatchExpr) -> genMatchExpr(node)

	_ -> genErr('not implemented!')
}

genErr := msg => f('throw new Error("{{0}}")', [replace(msg, '"', '\\"')])
genEmpty := () => '__Ink_Empty'

genBooleanLiteral := node => string(node.val)
genNumberLiteral := node => string(node.val)
genStringLiteral := node => f('__Ink_String(`{{0}}`)', [replace(node.val, '`', '\\`')])

genListLiteral := node => '[' + cat(map(node.exprs, gen), ', ') + ']'

genObjectEntry := node => f('{{0}}: {{1}}', [
	node.key.type :: {
		(Node.Ident) -> gen(node.key)
		(Node.EmptyIdent) -> gen(node.key)
		(Node.NumberLiteral) -> gen(node.key)
		_ -> '[' + gen(node.key) + ']'
	}
	gen(node.val)
])
genObjectLiteral := node => '{' + cat(map(node.entries, genObjectEntry), ', ') + '}'

` some expressions (like assignments to variables ) are expressions in Ink
	but statements in JS, and cannot be returned. This helper fn adds a workaround
	so that we can "return assignments" by returning a reference to the assigned variable. `
genAsReturn := node => [node.type, node.op, ident?(node.left)] :: {
	[Node.BinaryExpr, Tok.DefineOp, true] -> f('{{0}}; return {{1}}', [gen(node), gen(node.left)])
	_ -> f('return {{0}}', [gen(node)])
}

genFnArg := (node, i) => node.type :: {
	(Node.Ident) -> genIdent(node)
	(Node.EmptyIdent) -> '__' + string(i) `` avoid duplicate arg names
	_ -> '__' + string(i)
}

genFnLiteral := node => f('{{0}} => {{1}}', [
	node.args :: {
		[_] -> genFnArg(node.args.0, 0)
		_ -> '(' + cat(map(node.args, genFnArg), ', ') + ')'
	}
	node.body.type :: {
		(Node.ObjectLiteral) -> '(' + gen(node.body) + ')'
		(Node.ExprList) -> gen(node.body)
		_ -> node.body.decl? :: {
			true -> '{' + genAsReturn(node.body) + '}'
			_ -> gen(node.body)
		}
	}
])

genFnCall := node => f(
	'{{0}}({{1}})'
	[
		node.fn.type :: {
			(Node.FnLiteral) -> '(' + gen(node.fn) + ')'
			_ -> gen(node.fn)
		}
		cat(map(node.args, gen), ', ')
	]
)

genUnaryExpr := node => node.op :: {
	(Tok.NegOp) -> f('__ink_negate({{ 0 }})', [gen(node.left)])
	_ -> genErr(f('UnaryExpr with unknown op: {{0}}', [node.op]))
}

genBinaryExpr := node => node.op :: {
	(Tok.AddOp) -> f(
		'__as_ink_string({{0}} + {{1}})'
		[gen(node.left), gen(node.right)]
	)
	(Tok.SubOp) -> f('({{0}} - {{1}})', [gen(node.left), gen(node.right)])
	(Tok.MulOp) -> f('({{0}} * {{1}})', [gen(node.left), gen(node.right)])
	(Tok.DivOp) -> f('({{0}} / {{1}})', [gen(node.left), gen(node.right)])
	(Tok.ModOp) -> f('({{0}} % {{1}})', [gen(node.left), gen(node.right)])

	(Tok.AndOp) -> f('__ink_and({{0}}, {{1}})', [gen(node.left), gen(node.right)])
	(Tok.XorOp) -> f('__ink_xor({{0}}, {{1}})', [gen(node.left), gen(node.right)])
	(Tok.OrOp) -> f('__ink_or({{0}}, {{1}})', [gen(node.left), gen(node.right)])

	(Tok.EqOp) -> f('__ink_eq({{0}}, {{1}})', [gen(node.left), gen(node.right)])
	(Tok.GtOp) -> f('({{0}} > {{1}})', [gen(node.left), gen(node.right)])
	(Tok.LtOp) -> f('({{0}} < {{1}})', [gen(node.left), gen(node.right)])

	(Tok.DefineOp) -> node.decl? :: {
		true -> f('let {{0}} = {{1}}', [gen(node.left), gen(node.right)])
		_ -> [node.left.type, node.left.op] :: {
			` DefineOp on a property `
			[Node.BinaryExpr, Tok.AccessorOp] -> (
				tmpDfn := clone(node.left)
				tmpDfn.left := {
					type: Node.Ident
					val: '__ink_assgn_trgt'
				}
				f(
					` this production preserves two Ink semantics:
						- strings can be mutably assigned to.
						- assignment on strings and composites return the
							assignment target, not the assigned value,
							as the value of the expression. `
					cat([
						'(() => {let __ink_assgn_trgt = __as_ink_string({{0}})'
						'__is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign({{3}}, {{2}}) : {{1}} = {{2}}'
						'return __ink_assgn_trgt})()'
					], '; ')
					[
						gen(node.left.left)

						` composite assignment `
						genDefineTarget(tmpDfn)
						gen(node.right)

						` string assignment `
						gen(node.left.right)
					]
				)
			)
			_ -> f('{{0}} = {{1}}', [genDefineTarget(node.left), gen(node.right)])
		}
	}

	(Tok.AccessorOp) -> node.right.type :: {
		(Node.Ident) -> f(
			cat([
				'(() => {let __ink_acc_trgt = __as_ink_string({{0}})'
				'return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[{{1}}] || null : (__ink_acc_trgt.{{1}} !== undefined ? __ink_acc_trgt.{{1}} : null)})()'
			], '; ')
			[gen(node.left), gen(node.right)]
		)
		_ -> f(
			cat([
				'(() => {let __ink_acc_trgt = __as_ink_string({{0}})'
				'return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[{{1}}] || null : (__ink_acc_trgt[{{1}}] !== undefined ? __ink_acc_trgt[{{1}}] : null)})()'
			], '; ')
			[gen(node.left), gen(node.right)]
		)
	}

	_ -> genErr(f('BinaryExpr with unknown op: {{0}}', [node.op]))
}

genDefineTarget := node => node.type :: {
	(Node.BinaryExpr) -> node.right.type :: {
		(Node.Ident) -> f('({{0}}.{{1}})', [gen(node.left), gen(node.right)])
		_ -> f('({{0}}[{{1}}])', [gen(node.left), gen(node.right)])
	}
	_ -> gen(node)
}

genIdent := node => node.val :: {
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

genExprListExprs := exprs => '(() => {' + cat(map(exprs, (expr, i) => (
	i + 1 :: {
		len(exprs) -> genAsReturn(expr)
		_ -> gen(expr)
	}
)), '; ') + '})()'

genExprList := node => node.exprs :: {
	[] -> 'null'
	[_] -> node.exprs.(0).decl? :: {
		false -> f('({{0}})', [gen(node.exprs.0)])
		_ -> genExprListExprs(node.exprs)
	}
	_ -> genExprListExprs(node.exprs)
}

genMatchExpr := node => f('__ink_match({{0}}, [{{1}}])', [
	gen(node.condition)
	cat(map(node.clauses, genMatchClause), ', ')
])

genMatchClause := node => f('[() => ({{0}}), () => ({{1}})]', [
	gen(node.target)
	gen(node.expr)
])
