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

decl? := expr => expr.type = Node.BinaryExpr & expr.op = Tok.DefineOp & ident?(expr.left)

analyzeSubexpr := (node, ctx, tail?) => node.type :: {
	Node.ExprList -> (
		ctx := clone(ctx)

		ctx.decls := {}
		node.exprs := map(
			node.exprs
			(n, i) => analyzeSubexpr(n, ctx, i + 1 = len(node.exprs))
		)

		` do not re-declare function parameters `
		node.decls := filter(keys(ctx.decls), decl => ctx.args.(decl) = ())
		node
	)
	Node.FnLiteral -> (
		ctx := clone(ctx)

		` we ought only count as "recursion" when a function directly calls
		itself -- we do not count references to itself in other callbacks,
		which may be called asynchronously. `
		ctx.enclosingFnLit :: {
			node -> ()
			_ -> ctx.enclosingFn := ()
		}

		ctx.decls := {}
		ctx.args := {}
		each(node.args, n => n.type :: {
			Node.Ident -> ctx.args.(n.val) := true
		})

		node.body := analyzeSubexpr(node.body, ctx, true)

		` do not re-declare function parameters `
		node.decls := filter(keys(ctx.decls), decl => ctx.args.(decl) = ())
		node
	)
	Node.MatchExpr -> (
		node.condition := analyzeSubexpr(node.condition, ctx, false)
		node.clauses := map(node.clauses, n => analyzeSubexpr(n, ctx, true))
		node
	)
	Node.MatchClause -> (
		node.target := analyzeSubexpr(node.target, ctx, false)
		node.expr := analyzeSubexpr(node.expr, ctx, true)
		node
	)
	Node.FnCall -> (
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
	Node.BinaryExpr -> (
		defn? := node.op = Tok.DefineOp
		simpleName? := node.left.type = Node.Ident
		fnLiteral? := node.right.type = Node.FnLiteral

		defn? & simpleName? & fnLiteral? :: {
			true -> (
				fnCtx := clone(ctx)
				fnCtx.enclosingFn := node.left
				fnCtx.enclosingFnLit := node.right

				node.left := analyzeSubexpr(node.left, ctx, false)
				node.right := analyzeSubexpr(node.right, fnCtx, false)

				fnCtx.enclosingFn.recurred? :: {
					true -> (
						trampolinedFnName := '__ink_trampolined_' + fnCtx.enclosingFn.val

						ctx.decls.(trampolinedFnName) := true

						node.right := {
							type: Node.FnLiteral
							args: clone(node.right.args)
							decls: []
							body: {
								type: Node.ExprList
								decls: []
								exprs: [
									{
										type: Node.BinaryExpr
										op: Tok.DefineOp
										left: {
											type: Node.Ident
											val: trampolinedFnName
										}
										right: node.right
									}
									{
										type: Node.FnCall
										fn: {
											type: Node.Ident
											val: '__ink_resolve_trampoline'
										}
										args: append([{
											type: Node.Ident
											val: trampolinedFnName
										}], clone(node.right.args))
									}
								]
							}
						}
					)
				}
			)
			_ -> (
				node.left := analyzeSubexpr(node.left, ctx, false)
				node.right := analyzeSubexpr(node.right, ctx, false)
			)
		}

		decl?(node) :: {
			true -> ctx.decls.(node.left.val) := true
		}

		node
	)
	Node.UnaryExpr -> node.left := analyzeSubexpr(node.left, ctx, false)
	Node.ObjectLiteral -> node.entries := map(node.entries, e => analyzeSubexpr(e, ctx, false))
	Node.ObjectEntry -> (
		node.key := analyzeSubexpr(node.key, ctx, false)
		node.val := analyzeSubexpr(node.val, ctx, false)
		node
	)
	Node.ListLiteral -> node.exprs := map(node.exprs, e => analyzeSubexpr(e, ctx, false))
	_ -> node
}

analyze := node => analyzeSubexpr(node, {
	decls: {}
	args: {}
}, false)
