` september translate command `

std := load('../vendor/std')

log := std.log
map := std.map
each := std.each

Tokenize := load('tokenize')
tokenize := Tokenize.tokenize
tkString := Tokenize.tkString

main := prog => (
	tokens := tokenize(prog)
	each(tokens, tok => log(tkString(tok)))
	(std.stringList)(map(tokens, tkString)) + char(10)
)
