` september translate command `

std := load('../vendor/std')

log := std.log
map := std.map
each := std.each

Tokenize := load('tokenize')
tokenize := Tokenize.tokenize
tkString := Tokenize.tkString

Parse := load('parse')
parse := Parse.parse

main := prog => (
	tokens := tokenize(prog)
	each(tokens, tok => log(tkString(tok)))

	string(parse(tokens)) + char(10)
)
