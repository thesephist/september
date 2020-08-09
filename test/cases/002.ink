` local and global variable scopes `

std := load('./runtime/std')

log := std.log

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

log('should print {x: yyy}, 2')

a := {}
log(a.x := 'yyy')
log(({}.to := 2).to)

` scope inside match clause condition in fn literal `
max := 1
fn := () => max := 3 :: {
	3 -> 'right'
	_ -> 'wrong'
}

log('should be 1, not 3')
fn()
log(max)
