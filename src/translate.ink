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

Render := load('render')
render := Render.render

Newline := char(10)

main := prog => (
	tokens := tokenize(prog)
	`` each(tokens, tok => log(tkString(tok)))

	nodes := parse(tokens)
	`` log(nodes)

	type(nodes) :: {
		` tree of nodes `
		'composite' -> cat(map(nodes, render), ';' + Newline) + ';' + Newline
		` was parse err `
		'string' -> nodes
	}
)
