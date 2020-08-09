# September 🐞

**September** is an Ink to JavaScript compiler and toolchain for cross-compiling Ink applications to Node.js and the Web. September aims to be self-hosting on Node.js.

## Usage

Currently, September supports one CLI command. Run

```
september translate <file1>.ink <file2>.ink
```

to translate Ink programs into JavaScript and print them to stdout.

## Transformations

September constructs an Ink parse tree and recursively translates each tree node into its JavaScript equivalent. Since Ink programs are semantically very similar to JavaScript programs, this straightforward translation works well.

Specifically, `september translate <file>.ink` will translate Ink program source files to JavaScript files and print them to stdout.

September makes the following translations.

### Unary and binary operators

- `~`: runtime function `__ink_negate` which performs a `-` if argument is number, `!` otherwise.
- Basic arithmetic (`+ - * / %`) are translated verbatim, because they are valid JavaScript.
- The equality comparison `=` does deep comparisons in Ink, which does not have a native JavaScript equivalent. Instead, we call out to a performance-optimized runtime function `__ink_eq` which has fast paths for simple types, and does deep comparisons for composite values.
- `>` and `<` are translated literally, as the semantics in Ink and JavaScript match.
- `.`: the property access operator works the same way in JavaScript (with some caveats outlined in the "composite values" section below), but the operator precedence is different. Specifically, function calls on the right side of `.` need to be parenthesized in JavaScript because it has higher precedence in Ink.
- Binary combinators `& | ^` have different behavior for numbers and booleans in Ink, so they call out to their respective runtime functions, `__ink_{and, or, xor}`.

### Values

- Ink **numbers** are 64-bit floating point numbers, and are translated directly to JavaScript `number` values.
- Ink **booleans** are `true` and `false` symbols and are translated literally to JavaScript boolean values.
- The null value `()` in Ink is translated to the `null` symbol in JavaScript.
- **strings** in Ink are mutable, which means we cannot simply substitute them for JavaScript strings. However, JavaScript strings are heavily optimized, and we want to take advantage of those optimizations. So to represent Ink strings, we wrap JavaScript strings 
- Translating **composite** values in Ink is more involved. While the value itself behaves like JavaScript objects or arrays, property access and assignment semantics differ, and Ink uses the single composite type for both list and map style data structures. Specifically, we make the following translations:
	- Composites initialized with `[]` are translated to JavaScript arrays.
	- Composites initialized with `{}` are translated to JavaScript object literals.
	- Assignment to a composite value is _always_ translated directly. i.e. The Ink program `c.(k) := v` is always translated to `c[k] = v`. Notably, `c.k := v` is also translated to `c[k] = v` because `k` can be a numeric identifier in Ink, as in `c.2 := 3`.
	- Property access like `c[k]` is wrapped with a nullability check. This is because accessing properties in Ink returns `()` but `undefined` in JavaScript, so we need to check if the returned value is `undefined` and return `null` instead if so.

Ink has a special value `_` (the empty identifier), which is mapped to a `Symbol` in JavaScript. The empty identifier has special semantics in equality checks, defined in `__ink_eq`.

### Variable binding and scope

Ink variables follow strict lexical binding and matches JavaScript's lexical binding rules. Because Ink variable bindings are always mutable, September defaults to translate all variable declarations (first variable reference in a scope) to a `let` declaration in JavaScript.

In Ink, a variable declaration is an expression; in JavaScript it is a statement. This means variable bindings may need to be pulled out of an expression in Ink into its own statement in JavaScript.

Further optimizations may be added in the future.

### Match expressions

	// TODO

### Functions

The behavior of Ink functions is a strict subset of that of JavaScript functions, so in translating Ink to JavaScript, we can map function definitions and invocations directly to JavaScript equivalents.

One caveat is that, although modern JavaScript functions are tail-call-optimized by specification, only JavaScriptCore (Safari) implements it in practice. This means functions with tail calls need to be optimized when September compiles them.

When calling a function that invokes tail calls (calls itself in a conditional branch by its original bound name within its body), September detects it and automatically unrolls it into a JavaScript `while` loop.

### Module system and imports

	// TODO

---

## Ideas and brainstorming

Torus interop layer

- Speak raw JDOM, not tagged templates.
- How should we interop with classes for components? Or is there a more idiomatic (Ink) way of composing views while keeping per-component local state?

