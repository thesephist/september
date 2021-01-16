std := load('../vendor/std')

log := std.log
f := std.format
map := std.map
each := std.each
filter := std.filter
clone := std.clone
append := std.append

Tokenize := load('tokenize')
Tok := Tokenize.Tok
tkString := Tokenize.tkString

Parse := load('parse')
Node := Parse.Node
ident? := Parse.ident?
ndString := Parse.ndString

analyzeSubexpr := (node, ctx, tail?) => node.type :: {
	(Node.ExprList) -> (
		declaredNames := (ctx.declaredNames :: {
			() -> {}
			_ -> ctx.declaredNames
		})

		ctx := clone(ctx)
		ctx.declaredNames := ()
		node.exprs := map(node.exprs, (n, i) => analyzeSubexpr(n, ctx, i + 1 = len(node.exprs)))

		` implement local lexical scope and let-keyword binding `
		defns := filter(
			node.exprs
			expr => [expr.type, expr.op, ident?(expr.left)] = [Node.BinaryExpr, Tok.DefineOp, true]
		)
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
		declaredNames := {}
		each(node.args, n => n.type :: {
			(Node.Ident) -> declaredNames.(n.val) := true
		})

		[node.body.type, node.body.op] :: {
			[Node.BinaryExpr, Tok.DefineOp] -> (
				node.body.left.type :: {
					(Node.Ident) -> declaredNames.(node.body.left.val) :: {
						() -> node.body.decl? := true
					}
				}
				analyzeSubexpr(node.body, ctx, true)
			)
			[Node.MatchExpr, _] -> (
				cond := node.body.condition
				[cond.type, cond.op, cond.left] :: {
					` catches the common case where a new variable is bound to
						the function scope within a naked match condition expression `
					[Node.BinaryExpr, Tok.DefineOp, {type: Node.Ident, val: _}] -> (
						tmpMatch := clone(node.body)
						tmpMatch.condition := cond.left
						node.body := {
							type: Node.ExprList
							exprs: [
								cond
								tmpMatch
							]
						}
					)
				}
				analyzeSubexpr(node.body, ctx, true)
			)
			[Node.ExprList, _] -> (
				bodyCtx := clone(ctx)
				bodyCtx.declaredNames := declaredNames
				analyzeSubexpr(node.body, bodyCtx, true)
			)
			_ -> analyzeSubexpr(node.body, ctx, true)
		}
		node
	)
	(Node.MatchExpr) -> (
		node.condition := analyzeSubexpr(node.condition, ctx, false)
		node.clauses := map(node.clauses, n => analyzeSubexpr(n, ctx, true))
		node
	)
	(Node.MatchClause) -> (
		node.target := analyzeSubexpr(node.target, ctx, false)
		node.expr := analyzeSubexpr(node.expr, ctx, true)
		node
	)
	(Node.FnCall) -> (
		node.fn := analyzeSubexpr(node.fn, ctx, false)
		node.args := map(node.args, n => analyzeSubexpr(n, ctx, false))

		simpleName? := node.fn.type = Node.Ident
		recursiveCall? := (ctx.enclosingFn :: {
			() -> false
			_ -> node.fn.val = ctx.enclosingFn.val
		})

		simpleName? & recursiveCall? & tail? :: {
			true -> (
				ctx.enclosingFn.recurred? := true

				{
					type: Node.FnCall
					fn: {
						type: Node.Ident
						val: '__ink_trampoline'
					}
					args: append([{
						type: Node.Ident
						val: '__ink_trampolined_' + node.fn.val
					}], node.args)
				}
			)
			_ -> node
		}
	)
	(Node.BinaryExpr) -> (
		defn? := node.op = Tok.DefineOp
		simpleName? := node.left.type = Node.Ident
		fnLiteral? := node.right.type = Node.FnLiteral

		defn? & simpleName? & fnLiteral? :: {
			true -> (
				fnCtx := clone(ctx)
				fnCtx.enclosingFn := node.left

				node.left := analyzeSubexpr(node.left, ctx, false)
				node.right := analyzeSubexpr(node.right, fnCtx, false)

				fnCtx.enclosingFn.recurred? :: {
					true -> node.right := {
						type: Node.FnLiteral
						args: clone(node.right.args)
						body: {
							type: Node.ExprList
							exprs: [
								{
									type: Node.BinaryExpr
									op: Tok.DefineOp
									left: {
										type: Node.Ident
										val: '__ink_trampolined_' + fnCtx.enclosingFn.val
									}
									right: node.right
									decl?: true
								}
								{
									type: Node.FnCall
									fn: {
										type: Node.Ident
										val: '__ink_resolve_trampoline'
									}
									args: append([{
										type: Node.Ident
										val: '__ink_trampolined_' + fnCtx.enclosingFn.val
									}], clone(node.right.args))
								}
							]
						}
					}
				}

				node
			)
			_ -> (
				node.left := analyzeSubexpr(node.left, ctx, false)
				node.right := analyzeSubexpr(node.right, ctx, false)
			)
		}

		node
	)
	_ -> node
}

analyze := node => analyzeSubexpr(node, {}, false)
