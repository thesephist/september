/**
 * Ink/JavaScript runtime/interop layer
 * implements Ink system interfaces for web and Node JS runtimes
 *
 * Ink builtins
 * TODO: all system interfaces for Node.js
 *
 * Ink semantics polyfill
 * __ink_negate
 * __ink_eq
 * __ink_and
 * __ink_or
 * __ink_xor
 * __ink_match
 *
 * Ink types
 * __Ink_Empty
 * __Ink_String constructor
 *
 * JavaScript interop
 * jsnew(constructor, [argument list]): invokes the JS constructor with given arguments
 */

function __ink_negate(x) {
	if (x === true) {
		return false;
	}
	if (x === false) {
		return true;
	}

	return -x;
}

function __ink_eq(a, b) {
	if (a === __Ink_Empty || b === __Ink_Empty) {
		return true;
	}

	if (a === null && b === null) {
		return true;
	}
	if (a === null || b === null) {
		return false;
	}

	if (typeof a !== typeof b) {
		return false;
	}
	if (a.__is_ink_string && b.__is_ink_string) {
		return a.valueOf() === b.valueOf();
	}
	if (typeof a === 'number' || typeof a === 'boolean') {
		return a === b;
	}

	// deep equality check for composite types
	if (typeof a !== 'object') {
		return false;
	}
	for (const key in a) {
		if (key in b) {
			if (__ink_eq(a[key], b[key])) {
				continue;
			}
			return false;
		}
		return false;
	}

	return false;
}

function __ink_and(a, b) {
	if (typeof a === 'boolean' && typeof b === 'boolean') {
		return a && b;
	}

	return a & b;
}

function __ink_or(a, b) {
	if (typeof a === 'boolean' && typeof b === 'boolean') {
		return a || b;
	}

	return a | b;
}

function __ink_xor(a, b) {
	if (typeof a === 'boolean' && typeof b === 'boolean') {
		return (a && !b) || (!a && b);
	}

	return a ^ b;
}

function __ink_match(cond, clauses) {
    for (const [target, expr] of clauses) {
        if (__ink_eq(cond, target())) {
            return expr();
        }
    }
    return null;
}

const __Ink_Empty = Symbol('__Ink_Empty');

const __Ink_String = s => {
	return {
		__is_ink_string: true,
		assign(i, slice) {
			if (i === s.length) {
				return s += slice;
			}

			return s = s.substr(0, i) + slice + s.substr(i + slice.length);
		},
		valueOf() {
			return s;
		},
	}
}

function jsnew(Constructor, args) {
	return new Constructor(...args);
}
