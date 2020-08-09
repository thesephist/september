` standard library `

std := load('./runtime/std')

log := std.log

log('000.ink~')

` ------------ `

cat := std.cat

log('should say 2')
log(type('ab'))
log(len('ab'))
log(cat(['a', 'b'], '--'))
