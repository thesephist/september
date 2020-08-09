all: run

# run main binary
run:
	./bin/main.ink translate test/cases/000.ink

# run all tests under test/
check:
	./bin/main.ink translate test/cases/*.ink
t: check

fmt:
	inkfmt fix bin/*.ink src/*.ink test/*.ink test/cases/*.ink
f: fmt

fmt-check:
	inkfmt bin/*.ink src/*.ink test/*.ink test/cases/*.ink
fk: fmt-check
