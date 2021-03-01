` object literal {} in a value position in match expression `

r := ({a: 'b', c: 42} :: {
	() -> 'wrong 1'
	{a: _, c: 42} -> 'right'
	_ -> 'wrong 2'
})

out('right: ')
out(r + char(10))

