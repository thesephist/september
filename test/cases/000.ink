log := x => (console.log)('' + x)

a := 2
log(a)
a := 5
log(a)

fn := x => a := x

x := 12
(a := x)

