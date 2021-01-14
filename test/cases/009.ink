` tail call elimination tests
	with a large fibonacci seq `

std := load('./runtime/std')

log := std.log
range := std.range
each := std.each

`` fibonacci
fib := n => (sub := (a, b, i) => i :: {
	0 -> a + b
	1 -> a + b
	_ -> (
		next := i - 1
		sub(b, a + b, next)
	)
})(0, 1, n)

each(range(0, 20, 1), n => log(fib(n)))

`` iterated sum

sub := (acc, i) => i :: {
	0 -> acc
	_ -> sub(acc + i, i - 1)
}

sum := n => sub(0, n)

each(map(range(1, 6, 1), exp => pow(10, exp)), n => log(sum(n)))

