/**
 * Ink/JavaScript runtime/interop layer
 * implements Ink system interfaces for web and Node JS runtimes
 */

const __NODE = typeof process === 'object';

/* Ink builtins */

function args() {
	return process.argv;
}

function __ink_in(cb) {
	// TODO
}

function out(s) {
	if (__NODE) {
		process.stdout.write(string(s).valueOf());
	} else {
		console.log(string(s).valueOf());
	}
	return null;
}

function dir(path, cb) {
	// TODO
}

function make(path, cb) {
	// TODO
}

function stat(path, cb) {
	// TODO
}

function read(path, offset, length, cb) {
	// TODO
}

function write(path, offset, data, cb) {
	// TODO
}

function __ink_delete(path, cb) {
	// TODO
}

function listen(host, handler) {
	// TODO
}

function req(data, callback) {
	// TODO
}

function rand() {
	return Math.random();
}

function urand(length) {
	// TODO
}

function time() {
	return Date.now() / 1000;
}

function wait(duration, cb) {
	setTimeout(cb, duration * 1000)
	return null;
}

function exec(path, args, stdin, stdoutFn) {
	// TODO
}

function sin(n) {
	return Math.sin(n);
}

function cos(n) {
	return Math.cos(n);
}

function asin(n) {
	return Math.asin(n);
}

function acos(n) {
	return Math.acos(n);
}

function pow(b, n) {
	return Math.pow(b, n);
}

function ln(n) {
	return Math.log(n);
}

function floor(n) {
	return ~~n;
}

function load(path) {
	if (__NODE) {
		return require(string(path).valueOf());
	} else {
		throw new Error('load() not implemented!');
	}
}

function __is_ink_string(x) {
	if (x == null) {
		return false;
	}
	return x.__is_ink_string;
}

function string(x) {
	if (x === null) {
		return __Ink_String('()');
	} else if (typeof x === 'number') {
		const sign = x > 0 ? 1 : -1;
		x = sign * x;
		const whole = ~~x;
		const frac = x - whole;
		const wholeStr = (sign * whole).toString();
		if (frac == 0) {
			return __Ink_String(wholeStr);
		} else {
			const fracStr = frac.toString().padEnd(10, '0').substr(1);
			return __Ink_String(wholeStr + fracStr);
		}
	} else if (__is_ink_string(x)) {
		return x;
	} else if (typeof x === 'boolean') {
		return __Ink_String(x.toString());
	} else if (typeof x === 'function') {
		return __Ink_String(x.toString()); // implementation-dependent, not specificied
	} else if (Array.isArray(x) || typeof x === 'object') {
		const entries = [];
		for (const key of keys(x)) {
			entries.push(`${key}: ${string(x[key])}`);
		}
		return __Ink_String('{' + entries.join(', ') + '}');
	} else if (x === undefined) {
		return __Ink_String('undefined'); // undefined behavior
	}
	return __Ink_String(x.toString()); // undefined behavior
}

function number(x) {
	// TODO
}

function point(c) {
	return c.charCodeAt(c);
}

function char(n) {
	return String.fromCharCode(n);
}

function type(x) {
	if (x === null) {
		return __Ink_String('()');
	} else if (typeof x === 'number') {
		return __Ink_String('number');
	} else if (__is_ink_string(x)) {
		return __Ink_String('string');
	} else if (typeof x === 'boolean') {
		return __Ink_String('boolean');
	} else if (typeof x === 'function') {
		return __Ink_String('function');
	} else if (Array.isArray(x) || typeof x === 'object') {
		return __Ink_String('composite');
	}
	return __Ink_String('');
}

function len(x) {
	switch (type(x).valueOf()) {
		case 'string':
			return x.length;
		case 'composite':
			if (Array.isArray(x)) {
				// -1 for .length
				return Object.getOwnPropertyNames(x).length - 1;
			} else {
				return Object.getOwnPropertyNames(x).length;
			}
	}
	throw new Error('len() takes a string or composite value, but got ' + string(x))
}

function keys(x) {
	if (type(x).valueOf() === 'composite') {
		if (Array.isArray(x)) {
			return Object.getOwnPropertyNames(x).filter(name => name !== 'length');
		} else {
			return Object.getOwnPropertyNames(x);
		}
	}
	throw new Error('keys() takes a composite value, but got ' + string(x).valueOf())
}

/* Ink semantics polyfill */

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
	if (__is_ink_string(a) && __is_ink_string(b)) {
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

/* Ink types */

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
		toString() {
			return s;
		},
		valueOf() {
			return s;
		},
	}
}

/* Ink -> JavaScript interop helpers */

function jsnew(Constructor, args) {
	return new Constructor(...args);
}
