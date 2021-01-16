#!/usr/bin/env ink

std := load('../vendor/std')

log := std.log
f := std.format
cat := std.cat

each := std.each
readFile := std.readFile

cli := load('../vendor/cli')

` september subcommands `
highlight := load('../src/highlight').main
translate := load('../src/translate').main

Newline := char(10)
Tab := char(9)
PreamblePath := './runtime/ink.js'

given := (cli.parsed)()
given.verb :: {
	` syntax-highlight input Ink programs from the token stream
		and print them to stdout `
	'print' -> (
		files := given.args
		each(files, path => (
			readFile(path, data => out(highlight(data)))
		))
	)
	` translate translates input Ink programs to JavaScript and
		print them to stdout `
	'translate' -> (
		files := given.args
		each(files, path => (
			readFile(path, data => out(translate(data)))
		))
	)
	'translate-full' -> readFile(PreamblePath, preamble => (
		js := [preamble]
		files := given.args
		each(files, path => readFile(path, data => (
			js.len(js) := translate(data)
			len(files) + 1 = len(js) :: {
				true -> log(cat(js, Newline))
			}
		)))
	))
	'run' -> readFile(PreamblePath, preamble => (
		js := [preamble]
		files := given.args
		each(files, path => readFile(path, data => (
			js.len(js) := translate(data)
			len(files) + 1 = len(js) :: {
				true -> exec(
					'node'
					['--']
					cat(js, ';' + Newline)
					evt => out(evt.data)
				)
			}
		)))
	))
	` start an interactive REPL backed by Node.js, if installed.
		might end up being the default behavior `
	'repl' -> log('command "repl" not implemented!')
	_ -> (
		commands := [
			'print'
			'translate'
			'translate-full'
			'run'
		]
		log(f('command "{{ verb }}" not recognized', given))
		log('September supports: ' + Newline + Tab +
				cat(commands, Newline + Tab))
	)
}
