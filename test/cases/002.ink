` local and global variable scopes `

log := x => (console.log)('' + x)

log('should print 2, 5, 5, 5, 20, 5')

a := 2
log(a)
a := 5
log(a)

fn := x => a := x
fn(10)
log(a)

x := 12
(a := x)
(
	a := 12
)
log(a)

scoped := () => (
	a := 10
	a := 20
	log(a)
)
scoped()
log(a)
