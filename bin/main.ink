#!/usr/bin/env ink

std := load('../vendor/std')

log := std.log
f := std.format

each := std.each
readFile := std.readFile

cli := load('../vendor/cli')

` september subcommands `
build := load('../src/build').main
translate := load('../src/translate').main

given := (cli.parsed)()
given.verb :: {
	` build takes an entrypoint Ink program and traverses
		its dependency graph to generate a single JavaScript binary
		that comprises the entire application `
	'build' -> log('command "build" not implemented!')
	` translate translates input Ink programs to JavaScript and
		print them to stdout `
	'translate' -> (
		files := given.args
		each(files, path => (
			readFile(path, data => out(translate(data)))
		))
	)
	` start an interactive REPL backed by Node.js, if installed.
		might end up being the default behavior `
	'repl' -> log('command "repl" not implemented!')
	_ -> (
		log(f('command "{{ verb }}" not recognized', given))
		log('September supports: build, translate')
		log(given)
	)
}
