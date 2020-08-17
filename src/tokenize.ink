std := load('../vendor/std')

log := std.log
f := std.format
slice := std.slice
map := std.map
reduce := std.reduce
every := std.every

str := load('../vendor/str')

digit? := str.digit?
hasPrefix? := str.hasPrefix?
index := str.index

mkiota := load('iota').new

Newline := char(10)
Tab := char(9)

iota := mkiota().next
Tok := {
	Separator: iota()

	Comment: iota()

	Ident: iota()
	EmptyIdent: iota()

	NumberLiteral: iota()
	StringLiteral: iota()

	TrueLiteral: iota()
	FalseLiteral: iota()

	AccessorOp: iota()

	EqOp: iota()
	FunctionArrow: iota()

	KeyValueSeparator: iota()
	DefineOp: iota()
	MatchColon: iota()

	CaseArrow: iota()
	SubOp: iota()

	NegOp: iota()
	AddOp: iota()
	MulOp: iota()
	DivOp: iota()
	ModOp: iota()
	GtOp: iota()
	LtOp: iota()

	AndOp: iota()
	OrOp: iota()
	XorOp: iota()

	LParen: iota()
	RParen: iota()
	LBracket: iota()
	RBracket: iota()
	LBrace: iota()
	RBrace: iota()
}

typeName := type => reduce(keys(Tok), (acc, k) => Tok.(k) :: {
	type -> k
	_ -> acc
}, '(unknown token)')

tkString := tok => f('{{ 0 }}({{ 1 }}) @ {{2}}:{{3}}'
	[typeName(tok.type), tok.val, tok.line, tok.col])

token := (type, val, line, col, i) => {
	type: type
	val: val
	line: line
	col: col
	i: i
}

tokenizeWithOpt := (s, lexComments) => (
	S := {
		i: ~1
		buf: ''
		strbuf: ''
		strbufLine: 0
		strbufCol: 0

		lastType: Tok.Separator
		line: 1
		col: 0

		inStringLiteral: false
	}
	tokens := []

	simpleCommit := tok => (
		S.lastType := tok.type
		tokens.len(tokens) := tok
	)
	simpleCommitChar := type => simpleCommit(token(
		type
		()
		S.line
		S.col
		type :: {
			(Tok.TrueLiteral) -> S.i - 4
			(Tok.FalseLiteral) -> S.i - 5
			_ -> S.i - 1
		}
	))
	commitClear := () => S.buf :: {
		'' -> _
		_ -> (
			cbuf := S.buf
			S.buf := ''
			cbuf :: {
				'true' -> simpleCommitChar(Tok.TrueLiteral)
				'false' -> simpleCommitChar(Tok.FalseLiteral)
				_ -> digit?(cbuf) :: {
					true -> simpleCommit(token(
						Tok.NumberLiteral
						number(cbuf)
						S.line
						S.col - len(cbuf)
						S.i - len(cbuf)
					))
					false -> simpleCommit(token(
						Tok.Ident
						cbuf
						S.line
						S.col - len(cbuf)
						S.i - len(cbuf)
					))
				}
			}
		)
	}
	commit := tok => (
		commitClear()
		simpleCommit(tok)
	)
	commitChar := type => commit(token(type, (), S.line, S.col, S.i))
	ensureSeparator := () => (
		commitClear()
		S.lastType :: {
			(Tok.Separator) -> ()
			(Tok.LParen) -> ()
			(Tok.LBracket) -> ()
			(Tok.LBrace) -> ()
			(Tok.AddOp) -> ()
			(Tok.SubOp) -> ()
			(Tok.MulOp) -> ()
			(Tok.DivOp) -> ()
			(Tok.ModOp) -> ()
			(Tok.NegOp) -> ()
			(Tok.GtOp) -> ()
			(Tok.LtOp) -> ()
			(Tok.EqOp) -> ()
			(Tok.DefineOp) -> ()
			(Tok.AccessorOp) -> ()
			(Tok.KeyValueSeparator) -> ()
			(Tok.FunctionArrow) -> ()
			(Tok.MatchColon) -> ()
			(Tok.CaseArrow) -> ()
			_ -> commitChar(Tok.Separator)
		}
	)
	finalize := () => (
		ensureSeparator()
		tokens
	)

	hasPrefix?(s, '#!') :: {
		true -> (
			S.i := index(s, Newline)
			S.line := S.line + 1
		)
	}

	(sub := () => (
		S.i := S.i + 1
		S.col := S.col + 1
		c := s.(S.i)
		[c, S.inStringLiteral] :: {
			[(), _] -> finalize()
			['\'', _] -> S.inStringLiteral :: {
				true -> (
					commit(token(
						Tok.StringLiteral
						S.strbuf
						S.strbufLine
						S.strbufCol
						S.i - len(S.strbuf) - 1
					))
					S.inStringLiteral := false
					sub()
				)
				false -> (
					S.strbuf := ''
					S.strbufLine := S.line
					S.strbufCol := S.col
					S.inStringLiteral := true
					sub()
				)
			}
			[_, true] -> c :: {
				Newline -> (
					S.line := S.line + 1
					S.col := 0
					S.strbuf := S.strbuf + c
					sub()
				)
				'\\' -> (
					S.i := S.i + 1
					S.strbuf := S.strbuf + s.(S.i)
					S.col := S.col + 1
					sub()
				)
				_ -> (
					S.strbuf := S.strbuf + c
					sub()
				)
			}
			_ -> c :: {
				'`' -> s.(S.i + 1) :: {
					` line comment `
					'`' -> advance := index(slice(s, S.i, len(s)), Newline) :: {
						~1 -> (
							lexComments :: {
								true -> commit(token(
									Tok.Comment
									slice(s, S.i, len(s))
									S.line
									S.col
									S.i
								))
							}
							finalize()
						)
						_ -> (
							line := S.line
							col := S.col
							i := S.i

							S.i := S.i + advance
							lexComments :: {
								true -> commit(token(
									Tok.Comment
									slice(s, i, S.i)
									line
									col
									i
								))
							}
							ensureSeparator()
							S.line := S.line + 1
							S.col := 0
							sub()
						)
					}
					_ -> (
						` block comment, keep taking until end of block `
						line := S.line
						col := S.col
						i := S.i

						S.i := S.i + 1
						(sub := () => s.(S.i) :: {
							'`' -> S.col := S.col + 1
							Newline -> (
								S.i := S.i + 1
								S.line := S.line + 1
								S.col := 0
								sub()
							)
							` comments that don't end should be ignored `
							() -> ()
							_ -> (
								S.i := S.i + 1
								S.col := S.col + 1
								sub()
							)
						})()
						lexComments :: {
							true -> commit(token(
								Tok.Comment
								slice(s, i, S.i + 1)
								line
								col
								i
							))
						}
						sub()
					)
				}
				Newline -> (
					ensureSeparator()
					S.line := S.line + 1
					S.col := 0
					sub()
				)
				Tab -> (
					commitClear()
					sub()
				)
				' ' -> (
					commitClear()
					sub()
				)
				'_' -> (
					commitChar(Tok.EmptyIdent)
					sub()
				)
				'~' -> (
					commitChar(Tok.NegOp)
					sub()
				)
				'+' -> (
					commitChar(Tok.AddOp)
					sub()
				)
				'*' -> (
					commitChar(Tok.MulOp)
					sub()
				)
				'/' -> (
					commitChar(Tok.DivOp)
					sub()
				)
				'%' -> (
					commitChar(Tok.ModOp)
					sub()
				)
				'&' -> (
					commitChar(Tok.AndOp)
					sub()
				)
				'|' -> (
					commitChar(Tok.OrOp)
					sub()
				)
				'^' -> (
					commitChar(Tok.XorOp)
					sub()
				)
				'<' -> (
					commitChar(Tok.LtOp)
					sub()
				)
				'>' -> (
					commitChar(Tok.GtOp)
					sub()
				)
				',' -> (
					ensureSeparator()
					sub()
				)
				'.' -> [S.buf, every(map(S.buf, digit?))] :: {
					['', _] -> (
						commitChar(Tok.AccessorOp)
						sub()
					)
					[_, true] -> (
						S.buf := S.buf + '.'
						sub()
					)
					_ -> (
						commitChar(Tok.AccessorOp)
						sub()
					)
				}
				':' -> s.(S.i + 1) :: {
					'=' -> (
						commitChar(Tok.DefineOp)
						S.i := S.i + 1
						sub()
					)
					':' -> (
						commitChar(Tok.MatchColon)
						S.i := S.i + 1
						sub()
					)
					_ -> (
						ensureSeparator()
						commitChar(Tok.KeyValueSeparator)
						sub()
					)
				}
				'=' -> s.(S.i + 1) :: {
					'>' -> (
						commitChar(Tok.FunctionArrow)
						S.i := S.i + 1
						sub()
					)
					_ -> (
						commitChar(Tok.EqOp)
						sub()
					)
				}
				'-' -> s.(S.i + 1) :: {
					'>' -> (
						commitChar(Tok.CaseArrow)
						S.i := S.i + 1
						sub()
					)
					_ -> (
						commitChar(Tok.SubOp)
						sub()
					)
				}
				'(' -> (
					commitChar(Tok.LParen)
					sub()
				)
				')' -> (
					ensureSeparator()
					commitChar(Tok.RParen)
					sub()
				)
				'[' -> (
					commitChar(Tok.LBracket)
					sub()
				)
				']' -> (
					ensureSeparator()
					commitChar(Tok.RBracket)
					sub()
				)
				'{' -> (
					commitChar(Tok.LBrace)
					sub()
				)
				'}' -> (
					ensureSeparator()
					commitChar(Tok.RBrace)
					sub()
				)
				_ -> (
					` strange hack required for mutating a nested string.
						might be an Ink interpreter bug... `
					S.buf := S.buf + c
					sub()
				)
			}
		}
	))()
)

tokenize := s => tokenizeWithOpt(s, false)

tokenizeWithComments := s => tokenizeWithOpt(s, true)
