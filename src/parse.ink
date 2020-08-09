std := load('../vendor/std')

log := std.log
slice := std.slice
each := std.each

Tokenize := load('tokenize')
Tok := Tokenize.Tok
tkString := Tokenize.tkString

mkiota := load('iota').new

iota := mkiota().next
Node := {
	UnaryExpr: iota()
	BinaryExpr: iota()

	FnCall: iota()

	MatchClause: iota()
	MatchExpr: iota()
	ExprList: iota()

	EmptyIdent: iota()
	Ident: iota()

	NumberLiteral: iota()
	StringLiteral: iota()
	BooleanLiteral: iota()
	ObjectLiteral: iota()
	ObjectEntry: iota()
	ListLiteral: iota()
	FnLiteral: iota()
}

nodeString := node => node.type :: {
	`` TODO: improve
	_ -> string(node)
}

opPriority := tok => tok.type :: {
	(Tok.AccessorOp) -> 100
	(Tok.ModOp) -> 80

	(Tok.MulOp) -> 50
	(Tok.DivOp) -> 50
	(Tok.AddOp) -> 40
	(Tok.SubOp) -> 40

	(Tok.GtOp) -> 30
	(Tok.LtOp) -> 30
	(Tok.EqOp) -> 30

	(Tok.AndOp) -> 20
	(Tok.XorOp) -> 15
	(Tok.OrOp) -> 10

	(Tok.DefineOp) -> 0

	_ -> ~1
}

isBinaryOp := tok => opPriority(tok) > ~1

parse := tokens => (
	nodes := []

	(tokens.0).type :: {
		(Tok.Separator) -> tokens := slice(tokens, 1, len(tokens))
	}

	(sub := idx => tokens.(idx) :: {
		() -> nodes
		_ -> (
			result := parseExpr(tokens, idx)
			log('parsed expr -> ' + string(result))
			result.err :: {
				() -> (
					nodes.len(nodes) := result.node
					sub(result.idx)
				)
				_ -> result.err
			}
		)
	})(0)
)

parseBinaryExpr := (left, op, prevPriority, tokens, idx) => (
	result := parseAtom(tokens, idx)
	right := result.node
	idx := result.idx

	S := {
		idx: idx
	}

	ops := [op]
	nodes := [left, right]
	result.err :: {
		() -> (sub := () => isBinaryOp(tokens.(S.idx)) :: {
			true -> (
				priority := opPriority(tokens.(S.idx))
				choices := [
					` priority is lower than the calling function's last op
						so return control to the parent binary op `
					~(prevPriority < priority)
					` priority is lower than the previous op but higher than
						the parent, so it's ok to be left-heavy in this tree`
					~(opPriority(ops.(len(ops) - 1)) < priority)
				]
				choices :: {
					[true, _] -> ()
					[_, true] -> (
						ops.len(ops) := tokens.(S.idx)
						S.idx := S.idx + 1

						tokens.(S.idx) :: {
							() -> {
								node: right
								idx: S.idx
								err: 'unexpected end of input, expected binary operator'
							}
							_ -> (
								result := parseAtom(tokens, S.idx)
								result.err :: {
									() -> (
										nodes.len(nodes) := result.node
										S.idx := result.idx
										sub()
									)
									_ -> result
								}
							)
						}
					)
					_ -> tokens.(S.idx) :: {
						() -> {
							node: right
							idx: S.idx
							err: 'unexpected end of input, expected binary operator'
						}
						_ -> (
							result := parseBinaryExpr(
								nodes.(len(nodes) - 1)
								tokens.(S.idx)
								opPriority(ops.(len(ops) - 1))
								tokens
								S.idx + 1
							)
							result.err :: {
								() -> (
									nodes.(len(nodes) - 1) := result.node
									S.idx := result.idx + 1
								)
								_ -> result
							}
						)
					}
				}
			)
		})()
		_ -> result
	}

	each(ops, (op, i) => (
		node := nodes.(i + 1)
		nodes.0 := {
			type: Node.BinaryExpr
			op: op.type
			left: nodes.0
			right: node
		}
	))

	{
		node: nodes.0
		idx: S.idx
		err: ()
	}
)

parseExpr := (tokens, idx) => (
	S := {
		idx: idx
	}

	consumeDanglingSeparator := () => tokens.(S.idx) :: {
		{type: Tok.Separator, val: _, line: _, col: _} -> S.idx := S.idx + 1
	}

	result := parseAtom(tokens, S.idx)
	atom := result.node
	result.err :: {
		() -> (
			S.idx := result.idx

			tokens.(S.idx) :: {
				() -> {
					node: ()
					idx: S.idx + 1
					err: 'unexpected end of input, expected continued expression'
				}
				_ -> (
					next := tokens.(S.idx)
					S.idx := S.idx + 1

					produceBinaryExpr := () => (
						result := parseBinaryExpr(atom, next, ~1, tokens, S.idx)
						binExpr := result.node
						S.idx := result.idx
						result.err :: {
							() -> tokens.(S.idx) :: {
								{type: Tok.MatchColon, val: _, line: _, col: _} -> (
									S.idx := S.idx + 1
									produceMatchExpr(binExpr)
								)
								_ -> (
									consumeDanglingSeparator()
									{
										node: binExpr
										idx: S.idx
										err: ()
									}
								)
							}
							_ -> result
						}
					)
					produceMatchExpr := condition => (
						result := parseMatchBody(tokens, S.idx)
						clauses := result.node
						S.idx := result.idx
						result.err :: {
							() -> (
								consumeDanglingSeparator()
								{
									node: {
										type: Node.MatchExpr
										clauses: clauses
									}
									idx: S.idx
								}
							)
							_ -> result
						}
					)

					next.type :: {
						(Tok.Separator) -> {
							node: atom
							idx: S.idx
							err: ()
						}
						` these belong to the parente atom that contains
							this expression, so return without consuming token `
						(Tok.KeyValueSeparator) -> {
							node: atom
							idx: S.idx - 1
							err: ()
						}
						(Tok.RightParen) -> {
							node: atom
							idx: S.idx - 1
							err: ()
						}
						(Tok.AddOp) -> produceBinaryExpr()
						(Tok.SubOp) -> produceBinaryExpr()
						(Tok.MulOp) -> produceBinaryExpr()
						(Tok.DivOp) -> produceBinaryExpr()
						(Tok.ModOp) -> produceBinaryExpr()
						(Tok.AndOp) -> produceBinaryExpr()
						(Tok.XorOp) -> produceBinaryExpr()
						(Tok.OrOp) -> produceBinaryExpr()
						(Tok.GtOp) -> produceBinaryExpr()
						(Tok.LtOp) -> produceBinaryExpr()
						(Tok.EqOp) -> produceBinaryExpr()
						(Tok.DefineOp) -> produceBinaryExpr()
						(Tok.AccessorOp) -> produceBinaryExpr()
						(Tok.MatchColon) -> produceMatchExpr(atom)
						_ -> {
							node: ()
							idx: S.idx
							err: 'not implemented!'
						}
					}
				)
			}
		)
		_ -> result
	}
)

parseAtom := (tokens, idx) => tokens.(idx) :: {
	() -> {
		node: ()
		idx: idx
		err: 'unexpected end of input, expected atom'
	}
	_ -> tokens.(idx).type :: {
		(Tok.NegOp) -> (
			result := parseAtom(tokens, idx + 1)
			result.err :: {
				() -> {
					node: {
						type: Node.UnaryExpr
						op: Tok.NegOp
						left: result.node
					}
					idx: result.idx
				}
				_ -> result
			}
		)
		_ -> tokens.(idx + 1) :: {
			() -> {
				node: ()
				idx: idx + 1
				err: 'unexpected end of input, expected start of atom'
			}
			_ -> (
				tok := tokens.(idx)

				consumePotentialFunctionCall := (fnNode, idx) => (
					tokens.(idx) :: {
						{type: Tok.LParen, val: _, line: _, col: _} -> (
							parseFnCall(fnNode, tokens, idx)
						)
						_ -> {
							node: fnNode
							idx: idx
						}
					}
				)

				tok.type :: {
					(Tok.NumberLiteral) -> {
						node: {
							type: Node.NumberLiteral
							val: tok.val
						}
						idx: idx + 1
					}
					(Tok.StringLiteral) -> {
						node: {
							type: Node.StringLiteral
							val: tok.val
						}
						idx: idx + 1
					}
					(Tok.TrueLiteral) -> {
						node: {
							type: Node.BooleanLiteral
							val: true
						}
						idx: idx + 1
					}
					(Tok.FalseLiteral) -> {
						node: {
							type: Node.BooleanLiteral
							val: false
						}
						idx: idx + 1
					}
					(Tok.Ident) -> tokens.(idx + 1).type :: {
						(Tok.FunctionArrow) -> parseFnLiteral(tokens, idx)
						_ -> consumePotentialFunctionCall({
							type: Node.Ident
							val: tok.val
						}, idx + 1)
					}
					(Tok.EmptyIdent) -> tokens.(idx + 1).type :: {
						(Tok.FunctionArrow) -> parseFnLiteral(tokens, idx)
						_ -> consumePotentialFunctionCall({
							type: Node.Ident
							val: tok.val
						}, idx + 1)
					}
					(Tok.LParen) -> (
						exprs := []
						result := (sub := (idx) => (
							result := parseExpr(tokens, idx)
							expr := result.node
							result.err :: {
								() -> (
									exprs.len(exprs) := expr
									tokens.(result.idx) :: {
										() -> {
											node: ()
											idx: result.idx
											err: 'unexpected end of input, expected )'
										}
										_ -> (
											sub(result.idx)
										)
									}
								)
								_ -> result
							}
						))(idx + 1)

						S := {
							idx: result.idx + 1
						}
						tokens.(S.idx) :: {
							() -> {
								node: ()
								idx: result.idx
								err: 'unexpected end of input, expected continued expression'
							}
							_ -> tokens.(S.idx).type :: {
								(Tok.FunctionArrow) -> parseFnLiteral(tokens, idx)
								_ -> consumePotentialFunctionCall({
									type: Node.ExprList
									exprs: exprs
								}, S.idx)
							}
						}
					)
					(Tok.LBrace) -> (
						` TODO: implement object literal `
					)
					(Tok.LBracket) -> (
						` TODO: implement list literal `
					)
					_ -> {
						node: ()
						idx: idx
						err: 'not implemented!'
					}
				}
			)
		}
	}
}

parseFnLiteral := (tokens, idx) => (
	args := []

	processBody := idx => tokens.(idx) :: {
		{type: Tok.FunctionArrow, val: _, line: _, col: _} -> (
			result := parseExpr(tokens, idx + 1)
			result.err :: {
				() -> {
					node: {
						type: Node.FnLiteral
						args: args
						body: result.node
					}
					` literal values should not consume trailing separators,
						but the parseExpr() above does, so we give that up
						here to account for it for the parent that called
						into this parseFnLiteral `
					idx: result.idx - 1
				}
				_ -> result
			}
		)
		_ -> {
			node: ()
			idx: idx
			error: 'unexpected end of input, expected =>'
		}
	}

	tok := tokens.(idx)
	tok :: {
		() -> {
			node: ()
			idx: idx
			err: 'unexpected end of input, expected fn args list'
		}
		_ -> tok.type :: {
			(Tok.EmptyIdent) -> processBody(idx + 1)
			(Tok.Ident) -> (
				args.0 := {
					type: Node.Ident
					val: tok.val
				}
				processBody(idx + 1)
			)
			(Tok.LParen) -> (
				result := (sub := (idx) => (
					result := parseExpr(tokens, idx)
					expr := result.node
					result.err :: {
						() -> (
							args.len(args) := expr
							tokens.(result.idx) :: {
								() -> {
									node: ()
									idx: result.idx
									err: 'unexpected end of input, expected )'
								}
								_ -> (
									sub(result.idx)
								)
							}
						)
						_ -> result
					}
				))(idx + 1)

				processBody(result.idx)
			)
			_ -> {
				node: ()
				idx: idx
				err: 'unexpected token, expected start of fn literal'
			}
		}
	}
)

parseFnCall := (fnNode, tokens, idx) => (
	args := []

	tokens.(idx + 1) :: {
		() -> {
			node: ()
			idx: idx
			err: 'unexpected end of input, expected fn args list'
		}
		_ -> (
			result := (sub := (idx) => (
				result := parseExpr(tokens, idx)
				expr := result.node
				result.err :: {
					() -> (
						args.len(args) := expr
						tokens.(result.idx) :: {
							() -> {
								node: ()
								idx: result.idx
								err: 'unexpected end of input, expected )'
							}
							_ -> (
								sub(result.idx)
							)
						}
					)
					_ -> result
				}
			))(idx + 1)

			{
				node: {
					type: Node.FnCall
					fn: fnNode
					args: args
				}
				idx: result.idx + 1 `` RParen
			}
		)
	}
)

