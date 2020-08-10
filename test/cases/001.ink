` arithmetic, variables, functions, match exprs `

a := 2
b := 3

double := x => 2 * x

(console.log)(double(a + b))

log := x => out(string(x) + char(10))

even? := n => n % 2 :: {
	0 -> true
	_ -> false
}
log(even?(2))
log(even?(3))
log(even?(4))
log(even?(5))

log('Hello, World!')

fn := y => {hi: y}
log(fn('hello').hi)
