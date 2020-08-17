` september syntax highlighter command `

std := load('../vendor/std')

log := std.log
map := std.map
each := std.each
slice := std.slice
cat := std.cat

ansi := load('../vendor/ansi')

Norm := s => s
Gray := ansi.Gray
Red := ansi.Red
Green := ansi.Green
Yellow := ansi.Yellow
Blue := ansi.Blue
Magenta := ansi.Magenta
Cyan := ansi.Cyan

Tokenize := load('tokenize')
Tok := Tokenize.Tok
tokenize := Tokenize.tokenizeWithComments

Newline := char(10)

` associating token types with their highlight colors `
colorFn := tok => tok.type :: {
	(Tok.Separator) -> Norm

	(Tok.Comment) -> Gray

	(Tok.Ident) -> Norm
	(Tok.EmptyIdent) -> Norm

	(Tok.NumberLiteral) -> Magenta
	(Tok.StringLiteral) -> Yellow
	(Tok.TrueLiteral) -> Magenta
	(Tok.FalseLiteral) -> Magenta

	(Tok.AccessorOp) -> Red
	(Tok.EqOp) -> Red

	(Tok.FunctionArrow) -> Green

	` operators are all red `
	(Tok.KeyValueSeparator) -> Red
	(Tok.DefineOp) -> Red
	(Tok.MatchColon) -> Red
	(Tok.CaseArrow) -> Red
	(Tok.SubOp) -> Red
	(Tok.NegOp) -> Red
	(Tok.AddOp) -> Red
	(Tok.MulOp) -> Red
	(Tok.DivOp) -> Red
	(Tok.ModOp) -> Red
	(Tok.GtOp) -> Red
	(Tok.LtOp) -> Red
	(Tok.AndOp) -> Red
	(Tok.OrOp) -> Red
	(Tok.XorOp) -> Red

	(Tok.LParen) -> Cyan
	(Tok.RParen) -> Cyan
	(Tok.LBracket) -> Cyan
	(Tok.RBracket) -> Cyan
	(Tok.LBrace) -> Cyan
	(Tok.RBrace) -> Cyan
	_ -> () `` should error, unreachable
}

main := prog => (
	tokens := tokenize(prog)
	spans := map(tokens, (tok, i) => {
		colorFn: [tok.type, tokens.(i + 1)] :: {
			` direct function calls are marked green
				on a best-effort basis `
			[
				Tok.Ident
				{type: Tok.LParen, val: _, line: _, col: _, i: _}
			] -> Green
			_ -> colorFn(tok)
		}
		start: tok.i
		end: tokens.(i + 1) :: {
			() -> len(prog)
			_ -> tokens.(i + 1).i
		}
	})
	pcs := map(
		spans
		span => (span.colorFn)(slice(prog, span.start, span.end))
	)
	cat(pcs, '')
)
