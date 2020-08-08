`` literals

1 + 2
true = false
obj := {
	key: 'value'
	other: 9.8690
}
(console.log)('Hello, World!')

log := console.log
log(window.location.href)

type('hello') :: {
	'string' -> log('is a string')
	_ -> log(())
}
