a := 2
b := 3

double := x => 2 * x

(console.log)(double(a + b))

even? := n => n % 2 :: {
	0 -> true
	_ -> false
}
(console.log)(even?(2))
(console.log)(even?(3))
(console.log)(even?(5))
