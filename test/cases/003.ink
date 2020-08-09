` objects and lists `

obj := {
	first: 1
	second: 2
	third: 3
	fourth: {
		fifth: ~4.5
	}
}
arr := [1, 2, 3, 4, 5]

log := x => out(string(x) + char(10))

log(len(obj))
log(len(arr))

log(true)
log(false)

log(keys(obj))
log(keys(arr))

log(obj)
log(arr)

log(log)

