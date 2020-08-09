` objects and lists `

keys := Object.keys

obj := {
	first: 1
	second: 2
	third: 3
}

log := x => (console.log)('' + x)

log(keys(obj))
