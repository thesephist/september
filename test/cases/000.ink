` standard library `

std := load('./runtime/std')

log := std.log

log('000.ink~')

` ------------ `

cat := std.cat

`` log(cat(['a', 'b'], '--'))
