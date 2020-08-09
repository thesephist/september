std := load('../vendor/std')

log := std.log
each := std.each
filter := std.filter
clone := std.clone

Tokenize := load('tokenize')
Tok := Tokenize.Tok
tkString := Tokenize.tkString

Parse := load('parse')
Node := Parse.Node
ndString := Parse.ndString

analyzeSubexpr := (node, ctx) => node.type :: {
	` TODO: recursively analyze all subexpressions of all nodes `
	(Node.ExprList) -> (
		each(node.exprs, n => analyzeSubexpr(n, ctx))

		` implement local lexical scope and let-keyword binding `
		defns := filter(
			node.exprs
			expr => [expr.type, expr.op, expr.left] = [Node.BinaryExpr, Tok.DefineOp, {type: Node.Ident, val: _}]
		)

		declaredNames := {}
		each(defns, defn => declaredNames.(defn.left.val) :: {
			true -> ()
			_ -> (
				` name declared for the first time in this scope here,
				so this needs to be a let-declaration `
				defn.decl? := true
				declaredNames.(defn.left.val) := true
			)
		})

		node
	)
	(Node.FnLiteral) -> (
		analyzeSubexpr(node.body, ctx)
		[node.body.type, node.body.op] :: {
			[Node.BinaryExpr, Tok.DefineOp] -> node.body.decl? := true
			[Node.MatchExpr, _] -> (
				cond := node.body.condition
				[cond.type, cond.op, cond.left] :: {
					` catches the common case where a new variable is bound to
						the function scope within a naked match condition expression `
					[Node.BinaryExpr Tok.DefineOp{type: Node.Ident, val: _}] -> (
						tmpMatch := clone(node.body)
						tmpMatch.condition := cond.left
						node.body := {
							type: Node.ExprList
							exprs: [
								cond
								tmpMatch
							]
						}
						analyzeSubexpr(node.body, ctx)
					)
					_ -> analyzeSubexpr(node.body, ctx)
				}
			)
			_ -> analyzeSubexpr(node.body, ctx)
		}
	)
	(Node.MatchExpr) -> (
		analyzeSubexpr(node.condition, ctx)
		each(node.clauses, n => analyzeSubexpr(n, ctx))
		node
	)
	(Node.BinaryExpr) -> (
		analyzeSubexpr(node.left, ctx)
		analyzeSubexpr(node.right, ctx)
		node
	)
	_ -> node
}

analyze := node => analyzeSubexpr(node, {})
