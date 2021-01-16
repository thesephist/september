const std = require('./std');
map = (() => {let __ink_acc_trgt = __as_ink_string(std); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[map] || null : (__ink_acc_trgt.map !== undefined ? __ink_acc_trgt.map : null)})();
module.exports.map = map;
slice = (() => {let __ink_acc_trgt = __as_ink_string(std); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[slice] || null : (__ink_acc_trgt.slice !== undefined ? __ink_acc_trgt.slice : null)})();
module.exports.slice = slice;
reduce = (() => {let __ink_acc_trgt = __as_ink_string(std); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[reduce] || null : (__ink_acc_trgt.reduce !== undefined ? __ink_acc_trgt.reduce : null)})();
module.exports.reduce = reduce;
reduceBack = (() => {let __ink_acc_trgt = __as_ink_string(std); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[reduceBack] || null : (__ink_acc_trgt.reduceBack !== undefined ? __ink_acc_trgt.reduceBack : null)})();
module.exports.reduceBack = reduceBack;
checkRange = (lo, hi) => {return c => (() => {let p = point(c); return __ink_and((lo < p), (p < hi))})()};
module.exports.checkRange = checkRange;
upper__ink_qm__ = checkRange((point(__Ink_String(`A`)) - 1), __as_ink_string(point(__Ink_String(`Z`)) + 1));
module.exports.upper__ink_qm__ = upper__ink_qm__;
lower__ink_qm__ = checkRange((point(__Ink_String(`a`)) - 1), __as_ink_string(point(__Ink_String(`z`)) + 1));
module.exports.lower__ink_qm__ = lower__ink_qm__;
digit__ink_qm__ = checkRange((point(__Ink_String(`0`)) - 1), __as_ink_string(point(__Ink_String(`9`)) + 1));
module.exports.digit__ink_qm__ = digit__ink_qm__;
letter__ink_qm__ = c => {return __ink_or(upper__ink_qm__(c), lower__ink_qm__(c))};
module.exports.letter__ink_qm__ = letter__ink_qm__;
ws__ink_qm__ = c => {return __ink_match(point(c), [[() => 32, () => true], [() => 10, () => true], [() => 9, () => true], [() => 13, () => true], [() => __Ink_Empty, () => false]])};
module.exports.ws__ink_qm__ = ws__ink_qm__;
hasPrefix__ink_qm__ = (s, prefix) => {return reduce(prefix, (acc, c, i) => {return __ink_and(acc, (() => {return __ink_eq((() => {let __ink_acc_trgt = __as_ink_string(s); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[(() => {return i})()] || null : (__ink_acc_trgt[(() => {return i})()] !== undefined ? __ink_acc_trgt[(() => {return i})()] : null)})(), c)})())}, true)};
module.exports.hasPrefix__ink_qm__ = hasPrefix__ink_qm__;
hasSuffix__ink_qm__ = (s, suffix) => (() => {let diff = (len(s) - len(suffix)); return reduce(suffix, (acc, c, i) => {return __ink_and(acc, (() => {return __ink_eq((() => {let __ink_acc_trgt = __as_ink_string(s); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[(() => {return __as_ink_string(i + diff)})()] || null : (__ink_acc_trgt[(() => {return __as_ink_string(i + diff)})()] !== undefined ? __ink_acc_trgt[(() => {return __as_ink_string(i + diff)})()] : null)})(), c)})())}, true)})();
module.exports.hasSuffix__ink_qm__ = hasSuffix__ink_qm__;
matchesAt__ink_qm__ = (s, substring, idx) => (() => {let max = len(substring); return (() => {return sub = i => (() => {let __ink_trampolined_sub = i => {return __ink_match(i, [[() => max, () => true], [() => __Ink_Empty, () => __ink_match((() => {let __ink_acc_trgt = __as_ink_string(s); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[(() => {return __as_ink_string(idx + i)})()] || null : (__ink_acc_trgt[(() => {return __as_ink_string(idx + i)})()] !== undefined ? __ink_acc_trgt[(() => {return __as_ink_string(idx + i)})()] : null)})(), [[() => (() => {return (() => {let __ink_acc_trgt = __as_ink_string(substring); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[(() => {return i})()] || null : (__ink_acc_trgt[(() => {return i})()] !== undefined ? __ink_acc_trgt[(() => {return i})()] : null)})()})(), () => __ink_trampoline(__ink_trampolined_sub, __as_ink_string(i + 1))], [() => __Ink_Empty, () => false]])]])}; return __ink_resolve_trampoline(__ink_trampolined_sub, i)})()})()(0)})();
module.exports.matchesAt__ink_qm__ = matchesAt__ink_qm__;
index = (s, substring) => (() => {let max = (len(s) - 1); return (() => {return sub = i => (() => {let __ink_trampolined_sub = i => {return __ink_match(matchesAt__ink_qm__(s, substring, i), [[() => true, () => i], [() => false, () => __ink_match((i < max), [[() => true, () => __ink_trampoline(__ink_trampolined_sub, __as_ink_string(i + 1))], [() => false, () => __ink_negate(1)]])]])}; return __ink_resolve_trampoline(__ink_trampolined_sub, i)})()})()(0)})();
module.exports.index = index;
contains__ink_qm__ = (s, substring) => {return (index(s, substring) > __ink_negate(1))};
module.exports.contains__ink_qm__ = contains__ink_qm__;
lower = s => {return reduce(s, (acc, c, i) => {return __ink_match(upper__ink_qm__(c), [[() => true, () => (() => {let __ink_assgn_trgt = __as_ink_string(acc); __is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign((() => {return i})(), char(__as_ink_string(point(c) + 32))) : (__ink_assgn_trgt[(() => {return i})()]) = char(__as_ink_string(point(c) + 32)); return __ink_assgn_trgt})()], [() => false, () => (() => {let __ink_assgn_trgt = __as_ink_string(acc); __is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign((() => {return i})(), c) : (__ink_assgn_trgt[(() => {return i})()]) = c; return __ink_assgn_trgt})()]])}, __Ink_String(``))};
module.exports.lower = lower;
upper = s => {return reduce(s, (acc, c, i) => {return __ink_match(lower__ink_qm__(c), [[() => true, () => (() => {let __ink_assgn_trgt = __as_ink_string(acc); __is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign((() => {return i})(), char((point(c) - 32))) : (__ink_assgn_trgt[(() => {return i})()]) = char((point(c) - 32)); return __ink_assgn_trgt})()], [() => false, () => (() => {let __ink_assgn_trgt = __as_ink_string(acc); __is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign((() => {return i})(), c) : (__ink_assgn_trgt[(() => {return i})()]) = c; return __ink_assgn_trgt})()]])}, __Ink_String(``))};
module.exports.upper = upper;
title = s => (() => {let lowered = lower(s); return (() => {let __ink_assgn_trgt = __as_ink_string(lowered); __is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign(0, upper((() => {let __ink_acc_trgt = __as_ink_string(lowered); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[0] || null : (__ink_acc_trgt[0] !== undefined ? __ink_acc_trgt[0] : null)})())) : (__ink_assgn_trgt[0]) = upper((() => {let __ink_acc_trgt = __as_ink_string(lowered); return __is_ink_string(__ink_acc_trgt) ? __ink_acc_trgt.valueOf()[0] || null : (__ink_acc_trgt[0] !== undefined ? __ink_acc_trgt[0] : null)})()); return __ink_assgn_trgt})()})();
module.exports.title = title;
replaceNonEmpty = (s, old, __ink_ident_new) => (() => {let lold = len(old); let lnew = len(__ink_ident_new); return (() => {return sub = (acc, i) => (() => {let __ink_trampolined_sub = (acc, i) => {return __ink_match(matchesAt__ink_qm__(acc, old, i), [[() => true, () => __ink_trampoline(__ink_trampolined_sub, __as_ink_string(__as_ink_string(slice(acc, 0, i) + __ink_ident_new) + slice(acc, __as_ink_string(i + lold), len(acc))), __as_ink_string(i + lnew))], [() => false, () => __ink_match((i < len(acc)), [[() => true, () => __ink_trampoline(__ink_trampolined_sub, acc, __as_ink_string(i + 1))], [() => false, () => acc]])]])}; return __ink_resolve_trampoline(__ink_trampolined_sub, acc, i)})()})()(s, 0)})();
module.exports.replaceNonEmpty = replaceNonEmpty;
replace = (s, old, __ink_ident_new) => {return __ink_match(old, [[() => __Ink_String(``), () => s], [() => __Ink_Empty, () => replaceNonEmpty(s, old, __ink_ident_new)]])};
module.exports.replace = replace;
splitNonEmpty = (s, delim) => (() => {let coll = []; let ldelim = len(delim); return (() => {return sub = (acc, i, last) => (() => {let __ink_trampolined_sub = (acc, i, last) => {return __ink_match(matchesAt__ink_qm__(acc, delim, i), [[() => true, () => (() => {(() => {let __ink_assgn_trgt = __as_ink_string(coll); __is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign(len(coll), slice(acc, last, i)) : (__ink_assgn_trgt[len(coll)]) = slice(acc, last, i); return __ink_assgn_trgt})(); return __ink_trampoline(__ink_trampolined_sub, acc, __as_ink_string(i + ldelim), __as_ink_string(i + ldelim))})()], [() => false, () => __ink_match((i < len(acc)), [[() => true, () => __ink_trampoline(__ink_trampolined_sub, acc, __as_ink_string(i + 1), last)], [() => false, () => (() => {let __ink_assgn_trgt = __as_ink_string(coll); __is_ink_string(__ink_assgn_trgt) ? __ink_assgn_trgt.assign(len(coll), slice(acc, last, len(acc))) : (__ink_assgn_trgt[len(coll)]) = slice(acc, last, len(acc)); return __ink_assgn_trgt})()]])]])}; return __ink_resolve_trampoline(__ink_trampolined_sub, acc, i, last)})()})()(s, 0, 0)})();
module.exports.splitNonEmpty = splitNonEmpty;
split = (s, delim) => {return __ink_match(delim, [[() => __Ink_String(``), () => map(s, c => {return c})], [() => __Ink_Empty, () => splitNonEmpty(s, delim)]])};
module.exports.split = split;
trimPrefixNonEmpty = (s, prefix) => (() => {let max = len(s); let lpref = len(prefix); let idx = (() => {return sub = i => (() => {let __ink_trampolined_sub = i => {return __ink_match((i < max), [[() => true, () => __ink_match(matchesAt__ink_qm__(s, prefix, i), [[() => true, () => __ink_trampoline(__ink_trampolined_sub, __as_ink_string(i + lpref))], [() => false, () => i]])], [() => false, () => i]])}; return __ink_resolve_trampoline(__ink_trampolined_sub, i)})()})()(0); return slice(s, idx, len(s))})();
module.exports.trimPrefixNonEmpty = trimPrefixNonEmpty;
trimPrefix = (s, prefix) => {return __ink_match(prefix, [[() => __Ink_String(``), () => s], [() => __Ink_Empty, () => trimPrefixNonEmpty(s, prefix)]])};
module.exports.trimPrefix = trimPrefix;
trimSuffixNonEmpty = (s, suffix) => (() => {let lsuf = len(suffix); let idx = (() => {return sub = i => (() => {let __ink_trampolined_sub = i => {return __ink_match((i > __ink_negate(1)), [[() => true, () => __ink_match(matchesAt__ink_qm__(s, suffix, (i - lsuf)), [[() => true, () => __ink_trampoline(__ink_trampolined_sub, (i - lsuf))], [() => false, () => i]])], [() => false, () => i]])}; return __ink_resolve_trampoline(__ink_trampolined_sub, i)})()})()(len(s)); return slice(s, 0, idx)})();
module.exports.trimSuffixNonEmpty = trimSuffixNonEmpty;
trimSuffix = (s, suffix) => {return __ink_match(suffix, [[() => __Ink_String(``), () => s], [() => __Ink_Empty, () => trimSuffixNonEmpty(s, suffix)]])};
module.exports.trimSuffix = trimSuffix;
trim = (s, ss) => {return trimPrefix(trimSuffix(s, ss), ss)}
module.exports.trim = trim;
