` standard library `

std := load('./runtime/std')

log := std.log

log('000.ink~')

`` TODO: emulate cat
max := 1
fn := () => max := 3 :: {
	3 -> 'right'
	_ -> 'wrong'
}

log('should be 1, not 3')
log(fn())
log(max)
