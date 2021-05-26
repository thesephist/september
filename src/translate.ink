` september translate command `

std := load('../vendor/std')

log := std.log
map := std.map
each := std.each
cat := std.cat

Tokenize := load('tokenize')
tokenize := Tokenize.tokenize
tkString := Tokenize.tkString

Parse := load('parse')
parse := Parse.parse
ndString := Parse.ndString

Analyze := load('analyze')
analyze := Analyze.analyze

Gen := load('gen')
gen := Gen.gen

Newline := char(10)

main := prog => (
	tokens := tokenize(prog)
	`` each(tokens, tok => log(tkString(tok)))

	nodes := parse(tokens)

	type(nodes) :: {
		` tree of nodes `
		'composite' -> (
			`` each(nodes, node => log(ndString(node)))
			analyzed := map(nodes, analyze)
			cat(map(analyzed, gen), ';' + Newline) + Newline
		)
		` parse err `
		'string' -> nodes
	}
)
