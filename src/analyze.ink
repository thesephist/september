std := load('../vendor/std')

log := std.log
each := std.each

Tokenize := load('tokenize')
Tok := Tokenize.Tok
tkString := Tokenize.tkString

Parse := load('parse')
Node := Parse.Node
ndString := Parse.ndString

analyzeSubexpr := (node, ctx) => node.type :: {
	(Node.ExprList) -> (
		ctx := {scopeOwner: node}
		each(node.exprs, n => analyzeSubexpr(n, ctx))
		node
	)
	(Node.FnLiteral) -> (
		analyzeSubexpr(node.body, {scopeOwner: node})
		node
	)
	(Node.BinaryExpr) -> node.op :: {
		(Tok.DefineOp) -> ctx.scopeOwner :: {
			() -> node
			{type: Node.ExprList, exprs: _} -> (
				node.decl? := true
			)
			{type: Node.FnLiteral, args: _, body: _} -> (
				node.decl? := true
			)
			_ -> node
		}
		_ -> node
	}
	_ -> node
}

analyze := node => analyzeSubexpr(node, {
	scopeOwner: ()
})
