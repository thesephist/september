# September 🐞

**September** is an Ink to JavaScript compiler and toolchain for cross-compiling Ink applications to Node.js and the Web.

## Usage

## Transformations

September constructs an Ink parse tree and recursively translates each tree node into its JavaScript equivalent. Since Ink programs are semantically very similar to JavaScript programs, this straightforward translation works well.

Specifically, `september translate <file>.ink` will translate Ink program source files to JavaScript files and print them to stdout.

September makes the following translations.

	// TODO

## Ideas and brainstorming

Torus interop layer

- Speak raw JDOM, not tagged templates.
- How should we interop with classes for components? Or is there a more idiomatic (Ink) way of composing views while keeping per-component local state?

