std := load('../vendor/std')

log := std.log

Tokenize := load('tokenize')
Tok := Tokenize.Tok
tkString := Tokenize.tkString

Parse := load('parse')
Node := Parse.Node
ndString := Parse.ndString

analyze := node => (
	node
)
