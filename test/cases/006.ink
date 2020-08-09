` mutable string semantics `

std := load('./runtime/std')

log := std.log

log('expect: hello, hexxo, hexxowwy')

mutable := 'hello'
log(mutable)
mutable.2 := 'xx'
log(mutable)
mutable.len(mutable) := 'wwy'
log(mutable)

