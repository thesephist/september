std := load('../vendor/std')

log := std.log
f := std.format
slice := std.slice
map := std.map
each := std.each
cat := std.cat

Tokenize := load('tokenize')
Tok := Tokenize.Tok
typeName := Tokenize.typeName
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

ndString := node => node.type :: {
	(Node.NumberLiteral) -> f('Lit({{ val }})', node)
	(Node.StringLiteral) -> f('Lit({{ val }})', node)
	(Node.BooleanLiteral) -> f('Lit({{ val }})', node)

	(Node.UnaryExpr) -> f('UnrExpr({{0}} {{1}})'
		[typeName(node.op), ndString(node.left)])
	(Node.BinaryExpr) -> f('BinExpr({{0}} {{1}} {{2}})'
		[ndString(node.left), typeName(node.op), ndString(node.right)])

	(Node.Ident) -> f('Ident({{val}})', node)
	(Node.EmptyIdent) -> 'EmptyIdent'

	(Node.FnCall) -> f('Call({{0}} {{1}})', [
		ndString(node.fn)
		'(' + cat(map(node.args, ndString), ' ') + ')'
	])
	(Node.FnLiteral) -> f('Fn({{0}} {{1}})', [
		'(' + cat(map(node.args, ndString), ' ') + ')'
		ndString(node.body)
	])

	(Node.ExprList) -> '(' + cat(map(node.exprs, ndString), ' ') + ')'
	(Node.MatchExpr) -> f('Match({{0}} {{1}})', [
		ndString(node.condition)
		'{' + cat(map(node.clauses, ndString), ' ') + '}'
	])
	(Node.MatchClause) -> f('Clause({{0}} {{1}})'
		[ndString(node.target), ndString(node.expr)])

	(Node.ListLiteral) -> f('List({{0}})'
		[cat(map(node.exprs, ndString), ' ')])
	(Node.ObjectLiteral) -> f('Obj({{0}})'
		[cat(map(node.entries, ndString), ' ')])
	(Node.ObjectEntry) -> f('Entry({{0}} {{1}})'
		[ndString(node.key), ndString(node.val)])

	_ -> 'Unknown(' + string(node) + ')'
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

	tokens.0 :: {
		{type: Tok.Separator, val: _, line: _, col: _} -> (
			tokens := slice(tokens, 1, len(tokens))
		)
	}

	(sub := idx => tokens.(idx) :: {
		() -> nodes
		_ -> (
			result := parseExpr(tokens, idx)
			result.err :: {
				() -> (
					nodes.len(nodes) := result.node
					sub(result.idx)
				)
				_ -> f('parse err @ {{line}}:{{col}}: {{err}}', {
					err: result.err
					line: tokens.(result.idx).line
					col: tokens.(result.idx).col
				})
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
									S.idx := result.idx
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
										condition: condition
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
							err: 'token ' + tkString(next) + ' not implemented! (parseExpr)'
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
							type: Node.EmptyIdent
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
										_ -> tokens.(result.idx).type :: {
											(Tok.RParen) -> {
												node: result.node
												idx: result.idx + 1 `` RParen
											}
											_ -> sub(result.idx)
										}
									}
								)
								_ -> result
							}
						))(idx + 1)

						tokens.(result.idx) :: {
							() -> {
								node: ()
								idx: result.idx
								err: 'unexpected end of input, expected continued expression'
							}
							_ -> tokens.(result.idx).type :: {
								(Tok.FunctionArrow) -> parseFnLiteral(tokens, idx)
								_ -> consumePotentialFunctionCall({
									type: Node.ExprList
									exprs: exprs
								}, result.idx)
							}
						}
					)
					(Tok.LBrace) -> (
						entries := []
						result := (sub := (idx) => (
							result := parseObjectEntry(tokens, idx)
							entry := result.node
							result.err :: {
								() -> (
									entries.len(entries) := entry
									tokens.(result.idx) :: {
										() -> {
											node: ()
											idx: result.idx
											err: 'unexpected end of input, expected }'
										}
										_ -> tokens.(result.idx).type :: {
											(Tok.RBrace) -> {
												node: result.node
												idx: result.idx + 1 `` RBrace
											}
											_ -> sub(result.idx)
										}
									}
								)
								_ -> result
							}
						))(idx + 1) `` LBrace

						{
							node: {
								type: Node.ObjectLiteral
								entries: entries
							}
							idx: result.idx
						}
					)
					(Tok.LBracket) -> parseListLiteral(tokens, idx)
					_ -> {
						node: ()
						idx: idx
						err: 'token ' + tkString(tokens.(idx)) + ' not implemented! (parseAtom)'
					}
				}
			)
		}
	}
}

parseListLiteral := (tokens, idx) => (
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
					_ -> tokens.(result.idx).type :: {
						(Tok.RBracket) -> {
							node: result.node
							idx: result.idx + 1 `` RBracket
						}
						_ -> sub(result.idx)
					}
				}
			)
			_ -> result
		}
	))(idx + 1) `` LBracket

	{
		node: {
			type: Node.ListLiteral
			exprs: exprs
		}
		idx: result.idx
	}
)

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
								_ -> tokens.(result.idx).type :: {
									(Tok.RParen) -> {
										node: result.node
										idx: result.idx + 1 `` RParen
									}
									_ -> sub(result.idx)
								}
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
			idx: idx + 1
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
							_ -> tokens.(result.idx).type :: {
								(Tok.RParen) -> {
									node: result.node
									idx: result.idx + 1 `` RParen
								}
								_ -> sub(result.idx)
							}
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
				idx: result.idx
			}
		)
	}
)

parseMatchBody := (tokens, idx) => tokens.(idx + 1) :: {
	() -> {
		node: ()
		idx: idx + 1
		err: 'unexpected end of input, expected {'
	}
	_ -> (
		clauses := []
		result := (sub := (idx) => (
			result := parseMatchClause(tokens, idx)
			result.err :: {
				() -> (
					clauses.len(clauses) := result.node
					tokens.(result.idx) :: {
						() -> {
							node: ()
							idx: result.idx
							err: 'unexpected end of input, expected }'
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
			node: clauses
			idx: result.idx + 1 `` RBrace
		}
	)
}

parseMatchClause := (tokens, idx) => (
	result := parseAtom(tokens, idx)
	atom := result.node

	result.err :: {
		() -> tokens.(result.idx) :: {
			() -> {
				node: ()
				idx: result.idx
				err: 'unexpected end of input, expected ->'
			}
			_ -> tokens.(result.idx + 1) :: {
				() -> {
					node: ()
					idx: result.idx + 1
					err: 'unexpected end of input, expected expression in clause following ->'
				}
				_ -> (
					result := parseExpr(tokens, result.idx + 1)
					result.err :: {
						() -> {
							node: {
								type: Node.MatchClause
								target: atom
								expr: result.node
							}
							idx: result.idx
						}
						_ -> result
					}
				)
			}
		}
		_ -> result
	}
)

parseObjectEntry := (tokens, idx) => (
	result := parseExpr(tokens, idx)
	atom := result.node

	result.err :: {
		() -> tokens.(result.idx) :: {
			() -> {
				node: ()
				idx: result.idx
				err: 'unexpected end of input, expected :'
			}
			_ -> tokens.(result.idx + 1) :: {
				() -> {
					node: ()
					idx: result.idx + 1
					err: 'unexpected end of input, expected expression in clause following ->'
				}
				_ -> (
					result := parseExpr(tokens, result.idx + 1)
					result.err :: {
						() -> {
							node: {
								type: Node.ObjectEntry
								key: atom
								val: result.node
							}
							idx: result.idx
						}
						_ -> result
					}
				)
			}
		}
		_ -> result
	}
)
