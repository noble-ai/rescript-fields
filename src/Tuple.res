// This module contains both flattened and recursive definitions of Tuple, with equivalent operators for both.

let fst2 = ((a,_)) => a
let snd2 = ((_,b)) => b

// Conversion for translating between functions of multiple arguments and tuples of some degree.
// Functions are taken as named arguments so the resulting function can be piped easily.
let mapl2 = (~f, (a,b))  => (f(a), b)
let mapr2 = (~f, (a,b))  => (a, f(b))

type t2<'a, 'z> = ('a, 'z)
type t3<'a, 'b, 'z> = ('a, 'b, 'z)
type t4<'a, 'b, 'c, 'z> = ('a, 'b, 'c, 'z)
type t5<'a, 'b, 'c, 'd, 'z> = ('a, 'b, 'c, 'd, 'z)
type t6<'a, 'b, 'c, 'd, 'e, 'z> = ('a, 'b, 'c, 'd, 'e, 'z)
type t7<'a, 'b, 'c, 'd, 'e, 'f, 'z> = ('a, 'b, 'c, 'd, 'e, 'f, 'z)

type tuple1<'a> = t2<'a, ()>
type tuple2<'a, 'b> = t3<'a, 'b, ()>
type tuple3<'a, 'b, 'c> = t4<'a, 'b, 'c, ()>
type tuple4<'a, 'b, 'c, 'd> = t5<'a, 'b, 'c, 'd, ()>
type tuple5<'a, 'b, 'c, 'd, 'e> = t6<'a, 'b, 'c, 'd, 'e, ()>
type tuple6<'a, 'b, 'c, 'd, 'e, 'f> = t7<'a, 'b, 'c, 'd, 'e, 'f, ()>

let return2 = a => (a, a)
let return3 = a => (a, a, a)
let return4 = a => (a, a, a, a)
let return5 = a => (a, a, a, a, a)
let return6 = a => (a, a, a, a, a, a)

let curry2 = (fn, a, b)  => fn((a,b))
let curry3 = (fn, a, b, c)  => fn((a,b,c))
let curry4 = (fn, a, b, c, d)  => fn((a,b,c,d))
let curry5 = (fn, a, b, c, d, e)  => fn((a,b,c,d, e))
let curry6 = (fn, a, b, c, d, e, f)  => fn((a, b,c,d, e, f))

let uncurry2 = (fn, (a,b))  => fn(a, b)
let uncurry3 = (fn, (a,b, c))  => fn(a, b, c)
let uncurry4 = (fn, (a,b, c, d))  => fn(a, b, c, d)
let uncurry5 = (fn, (a,b, c, d, e))  => fn(a, b, c, d, e)
let uncurry6 = (fn, (a,b, c, d, e, f))  => fn(a, b, c, d, e, f)
	
let toList2 = ((a, b)): array<'a> => [a, b]
let toList3 = ((a, b, c)): array<'a> => [a, b, c]
let toList4 = ((a, b, c, d)): array<'a> => [a, b, c, d]
let toList5 = ((a, b, c, d, e)): array<'a> => [a, b, c, d, e]
let toList6 = ((a, b, c, d, e, f)): array<'a> => [a, b, c, d, e, f]

let napply2 = ((a, b), (x,y))  => (a(x), b(y))
let napply3 = ((a, b, c), (x,y,z))  => (a(x), b(y), c(z))
let napply4 = ((a, b, c, d), (w,x,y, z))  => (a(w), b(x), c(y), d(z))
let napply5 = ((a, b, c, d, e), (v, w,x,y, z))  => (a(v), b(w), c(x), d(y), e(z))
let napply6 = ((a, b, c, d, e, f), (u, v, w,x,y, z))  => (a(u), b(v), c(w), d(x), e(y), f(z))

// render a polymorphic tuple to an array
let mono = (napply, toList) => (f, t) => napply(f, t)->toList

// Some conveinences for tests
let all = (napply, toList) => (f, t) => napply(f, t)->toList->Array.all(x => x)
let some = (napply, toList) => (f, t) => napply(f, t)->toList->Array.some(x => x)

module Tuple2 = {
	type t<'a, 'b> = ('a, 'b)
	let make = (a, b) => (a, b)
	let uncurry = uncurry2
	let curry = curry2
	let return = return2
	let toList = toList2
	let napply = napply2
	// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
	let mono = (f, t) => napply(f, t)->toList
	let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
	let some = (f, t) => napply(f, t)->toList->Array.some(x => x)
}

module Tuple3 = {
	type t<'a, 'b, 'c> = ('a, 'b, 'c)
	let make = (a, b, c) => (a, b, c)
	let uncurry = uncurry3
	let curry = curry3
	let return = return3
	let toList = toList3
	let napply = napply3

	// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
	let mono = (f, t) => napply(f, t)->toList
	let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
	let some = (f, t) => napply(f, t)->toList->Array.some(x => x)
}

module Tuple4 = {
	type t<'a, 'b, 'c, 'd> = ('a, 'b, 'c, 'd)
	let make = (a, b, c, d) => (a, b, c, d) 
	let uncurry = uncurry4
	let curry = curry4
	let return = return4
	let toList = toList4
	let napply = napply4
	
	// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
	let mono = (f, t) => napply(f, t)->toList
	let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
	let some = (f, t) => napply(f, t)->toList->Array.some(x => x)
}

module Tuple5 = {
	type t<'a, 'b, 'c, 'd, 'e> = ('a, 'b, 'c, 'd, 'e)
	let make = (a, b, c, d, e) => (a, b, c, d, e) 
	let uncurry = uncurry5
	let curry = curry5
	let return = return5
	let toList = toList5
	let napply = napply5
	
	// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
	let mono = (f, t) => napply(f, t)->toList
	let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
	let some = (f, t) => napply(f, t)->toList->Array.some(x => x)
}

module Tuple6 = {
	type t<'a, 'b, 'c, 'd, 'e, 'f> = ('a, 'b, 'c, 'd, 'e, 'f)
	let make = (a, b, c, d, e, f) => (a, b, c, d, e, f) 
	let uncurry = uncurry6
	let curry = curry6
	let return = return6
	let toList = toList6
	let napply = napply6
	
	// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
	let mono = (f, t) => napply(f, t)->toList
	let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
	let some = (f, t) => napply(f, t)->toList->Array.some(x => x)
}

module Nested = {
	// build and manipulate nested tuples like https://pursuit.purescript.org/packages/purescript-tuples/7.0.0/docs/Data.Tuple.Nested, 
	// for church encoding in recursive fields, for example

	// The basic type for nested tuples is a tuple, but could be a variant e.g.
	type t<'a, 'z> = ('a, 'z)

	// Internal structure types 
	// planning to encode a unit as the z value
	// so we can pattern match
	// for termination in these recursive types
	type t2<'a, 'z> = t<'a, 'z>
	type t3<'a, 'b, 'z> = t<'a, t2<'b, 'z>>
	type t4<'a, 'b, 'c, 'z> = t<'a, t3<'b, 'c, 'z>>
	type t5<'a, 'b, 'c, 'd, 'z> = t<'a, t4<'b, 'c, 'd, 'z>>
	type t6<'a, 'b, 'c, 'd, 'e, 'z> = t<'a, t5<'b, 'c, 'd, 'e, 'z>>
	type t7<'a, 'b, 'c, 'd, 'e, 'f, 'z> = t<'a, t6<'b, 'c, 'd, 'e, 'f, 'z>>
	type t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'z> = t<'a, t7<'b, 'c, 'd, 'e, 'f, 'g, 'z>>
	type t9<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'z> = t<'a, t8<'b, 'c, 'd, 'e, 'f, 'g, 'h, 'z>>

	///....

	// Base tuple types with tail type z undefined
	// We will realize these as tupleN below with z as unit type, for termination
	// let t1: ('a) => tuple1<'a> = (a) => (a, ())
	let t2: ('a, 'z) => t2<'a, 'z> = (a, z) => (a, z)
	let t3: ('a, 'b, 'z) => t3<'a, 'b, 'z> = (a, b, z) => (a, (b, z))
	let t4: ('a, 'b, 'c, 'z) => t4<'a, 'b, 'c, 'z> = (a, b, c, z) => (a, (b, (c, z)))
	let t5: ('a, 'b, 'c, 'd, 'z) => t5<'a, 'b, 'c, 'd, 'z> = (a, b, c, d, z) => (a, (b, (c, (d, z))))
	let t6: ('a, 'b, 'c, 'd, 'e, 'z) => t6<'a, 'b, 'c, 'd, 'e, 'z> = (a, b, c, d, e, z) => (a, (b, (c, (d, (e, z)))))
	let t7: ('a, 'b, 'c, 'd, 'e, 'f, 'z) => t7<'a, 'b, 'c, 'd, 'e, 'f, 'z> = (a, b, c, d, e, f, z) => (a, (b, (c, (d, (e, (f, z))))))
  let t8: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'z) => t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'z> = (a, b, c, d, e, f, g, z) => (a, (b, (c, (d, (e, (f, (g, z)))))))	
	let t9: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'z) => t9<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, 'z> = (a, b, c, d, e, f, g, h, z) => (a, (b, (c, (d, (e, (f, (g, (h, z))))))))

	type tuple1<'a> = t2<'a, unit>
	type tuple2<'a, 'b> = t3<'a, 'b, unit>
	type tuple3<'a, 'b, 'c> = t4<'a, 'b, 'c, unit>
	type tuple4<'a, 'b, 'c, 'd> = t5<'a, 'b, 'c, 'd, unit>
	type tuple5<'a, 'b, 'c, 'd, 'e> = t6<'a, 'b, 'c, 'd, 'e, unit>
	type tuple6<'a, 'b, 'c, 'd, 'e, 'f> = t7<'a, 'b, 'c, 'd, 'e, 'f, unit>
	type tuple7<'a, 'b, 'c, 'd, 'e, 'f, 'g> = t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, unit>
	type tuple8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'h> = t9<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'h, unit>
	///....

	let tuple1: ('a) => tuple1<'a> = (a) => (a, ())
	let tuple2: ('a, 'b) => tuple2<'a, 'b> = (a, b) => (a, tuple1(b))
	let tuple3: ('a, 'b, 'c) => tuple3<'a, 'b, 'c> = (a, b, c) => (a, tuple2(b, c))
	let tuple4: ('a, 'b, 'c, 'd) => tuple4<'a, 'b, 'c, 'd> = (a, b, c, d) => (a, tuple3(b, c, d))
	let tuple5: ('a, 'b, 'c, 'd, 'e) => tuple5<'a, 'b, 'c, 'd, 'e> = (a, b, c, d, e) => (a, tuple4(b, c, d, e))
	let tuple6: ('a, 'b, 'c, 'd, 'e, 'f) => tuple6<'a, 'b, 'c, 'd, 'e, 'f> = (a, b, c, d, e, f) => (a, tuple5(b, c, d, e, f))
	let tuple7: ('a, 'b, 'c, 'd, 'e, 'f, 'g) => tuple7<'a, 'b, 'c, 'd, 'e, 'f, 'g> = (a, b, c, d, e, f, g) => (a, tuple6(b, c, d, e, f, g))
	let tuple8: ('a, 'b, 'c, 'd, 'e, 'f, 'g, 'h) => tuple8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'h> = (a, b, c, d, e, f, g, h) => (a, tuple7(b, c, d, e, f, g, h))
	///....

	let get1: (t2<'a, 'z>) => 'a = ((a, _)) => a
	let get2: (t3<'a, 'b, 'z>) => 'b = ((_, (b, _))) => b
	let get3: (t4<'a, 'b, 'c, 'z>) => 'c = ((_, b)) => b->get2
	let get4: (t5<'a, 'b, 'c, 'd, 'z>) => 'd = ((_, b)) => b->get3
	let get5: (t6<'a, 'b, 'c, 'd, 'e, 'z>) => 'e = ((_, b)) => b->get4
	let get6: (t7<'a, 'b, 'c, 'd, 'e, 'f, 'z>) => 'f = ((_, b)) => b->get5
	let get7: (t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'z>) => 'g = ((_, b)) => b->get6
	///....

	let set1: t2<'a, 'z> => 'b => t2<'b, 'z> = ((_, z), b) => (b, z)
	let set2: t3<'a, 'b, 'z> => 'c => t3<'a, 'b, 'z> = ((a, bz), c) => (a, set1(bz, c))
	let set3: t4<'a, 'b, 'c, 'z> => 'd => t4<'a, 'b, 'd, 'z> = ((a, bcz), d) => (a, set2(bcz, d))
	let set4: t5<'a, 'b, 'c, 'd, 'z> => 'e => t5<'a, 'b, 'c, 'e, 'z> = ((a, bcdz), e) => (a, set3(bcdz, e))
	let set5: t6<'a, 'b, 'c, 'd, 'e, 'z> => 'f => t6<'a, 'b, 'c, 'd, 'f, 'z> = ((a, bcdez), f) => (a, set4(bcdez, f))
	let set6: t7<'a, 'b, 'c, 'd, 'e, 'f, 'z> => 'f => t7<'a, 'b, 'c, 'd, 'e, 'f, 'z> = ((a, bcdefz), g) => (a, set5(bcdefz, g))
	let set7: t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'z> => 'f => t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'z> = ((a, bcdefgz), h) => (a, set6(bcdefgz, h))
	///....

// Apply the function to the nth field of the tuple
	let over1: (('a => 'r), t2<'a, 'z>) => t2<'r, 'z> = (fn, (a, z)) => (fn(a), z)
	let over2: (('b => 'r), t3<'a, 'b, 'z>) => t3<'a, 'r, 'z> = (fn, (a, (b, z))) => (a, (fn(b), z))
	let over3: (('c => 'r), t4<'a, 'b, 'c, 'z>) => t4<'a, 'b, 'r, 'z> = (fn, (a, (b, (c, z)))) => (a, (b, (fn(c), z)))
	let over4: (('d => 'r), t5<'a, 'b, 'c, 'd, 'z>) => t5<'a, 'b, 'r, 'd, 'z> = (fn, (a, (b, (c, (d, z))))) => (a, (b, (c, (fn(d), z))))
	let over5: (('e => 'r), t6<'a, 'b, 'c, 'd, 'e, 'z>) => t6<'a, 'b, 'r, 'd, 'e, 'z> = (fn, (a, (b, (c, (d, (e, z)))))) => (a, (b, (c, (d, (fn(e), z)))))
	let over6: (('f => 'r), t7<'a, 'b, 'c, 'd, 'e, 'f, 'z>) => t7<'a, 'b, 'r, 'd, 'e, 'f, 'z> = (fn, (a, (b, (c, (d, (e, (f, z))))))) => (a, (b, (c, (d, (e, (fn(f), z))))))
	let over7: (('g => 'r), t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'z>) => t8<'a, 'b, 'r, 'd, 'e, 'f, 'g, 'z> = (fn, (a, (b, (c, (d, (e, (f, (g, z)))))))) => (a, (b, (c, (d, (e, (f, (fn(g), z)))))))
	///....

	// TODO: should Z be fixed to unit?
	// TODO: should these take type tuple or native?
	let uncurry1: (('a) => 'r) => t2<'a, 'z> => 'r  = (fn, (a, _)) => fn(a)
	let uncurry2: (('a, 'b) => 'r) => t3<'a, 'b, 'z> => 'r = (fn, (a, (b, _))) => fn(a, b)
	let uncurry3: (('a, 'b, 'c) => 'r) => t4<'a, 'b, 'c, 'z> => 'r = (fn, (a, (b, (c, _)))) => fn(a, b, c)
	let uncurry4: (('a, 'b, 'c, 'd) => 'r) => t5<'a, 'b, 'c, 'd, 'z> => 'r = (fn, (a, (b, (c, (d, _))))) => fn(a, b, c, d)
	let uncurry5: (('a, 'b, 'c, 'd, 'e) => 'r) => t6<'a, 'b, 'c, 'd, 'e, 'z> => 'r = (fn, (a, (b, (c, (d, (e, _)))))) => fn(a, b, c, d, e)
	let uncurry6: (('a, 'b, 'c, 'd, 'e, 'f) => 'r) => t7<'a, 'b, 'c, 'd, 'e, 'f, 'z> => 'r = (fn, (a, (b, (c, (d, (e, (f, _))))))) => fn(a, b, c, d, e, f)
	let uncurry7: (('a, 'b, 'c, 'd, 'e, 'f, 'g) => 'r) => t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'z> => 'r = (fn, (a, (b, (c, (d, (e, (f, (g, _)))))))) => fn(a, b, c, d, e, f, g)
	///....

	let curry1: (t2<'a, 'z> => 'r) => 'a => 'r = (fn, a) => fn(tuple2(a, ()))
	let curry2: (t3<'a, 'b, 'z> => 'r) => 'a => 'b => 'r = (fn, a) => b => fn(tuple3(a, b, ()))
	let curry3: (t4<'a, 'b, 'c, 'z> => 'r) => 'a => 'b => 'c => 'r = (fn, a) => b => c => fn(tuple4(a, b, c, ()))
	let curry4: (t5<'a, 'b, 'c, 'd, 'z> => 'r) => 'a => 'b => 'c => 'd => 'r = (fn, a) => b => c => d => fn(tuple5(a, b, c, d, ()))
	let curry5: (t6<'a, 'b, 'c, 'd, 'e, 'z> => 'r) => 'a => 'b => 'c => 'd => 'e => 'r = (fn, a) => b => c => d => e => fn(tuple6(a, b, c, d, e, ()))
	let curry6: (t7<'a, 'b, 'c, 'd, 'e, 'f, 'z> => 'r) => 'a => 'b => 'c => 'd => 'e => 'f => 'r = (fn, a) => b => c => d => e => f => fn(tuple7(a, b, c, d, e, f, ()))
	let curry7: (t8<'a, 'b, 'c, 'd, 'e, 'f, 'g, 'z> => 'r) => 'a => 'b => 'c => 'd => 'e => 'f => 'g => 'r = (fn, a) => b => c => d => e => f => g => fn(tuple8(a, b, c, d, e, f, g, ()))
	///....

	let encode2: (('a, 'b)) => tuple2<'a, 'b> = ((a, b)) => tuple2(a, b)
	let encode3: (('a, 'b, 'c)) => tuple3<'a, 'b, 'c> = ((a, b, c)) => tuple3(a, b, c)
	let encode4: (('a, 'b, 'c, 'd)) => tuple4<'a, 'b, 'c, 'd> = ((a, b, c, d)) => tuple4(a, b, c, d)
	let encode5: (('a, 'b, 'c, 'd, 'e)) => tuple5<'a, 'b, 'c, 'd, 'e> = ((a, b, c, d, e)) => tuple5(a, b, c, d, e)
	let encode6: (('a, 'b, 'c, 'd, 'e, 'f)) => tuple6<'a, 'b, 'c, 'd, 'e, 'f> = ((a, b, c, d, e, f)) => tuple6(a, b, c, d, e, f)
	let encode7: (('a, 'b, 'c, 'd, 'e, 'f, 'g)) => tuple7<'a, 'b, 'c, 'd, 'e, 'f, 'g> = ((a, b, c, d, e, f, g)) => tuple7(a, b, c, d, e, f, g)

	let decode2: tuple2<'a, 'b> => ('a, 'b) = ((a, (b, ()))) => (a, b)
	let decode3: tuple3<'a, 'b, 'c> => ('a, 'b, 'c) = ((a, (b, (c, ())))) => (a, b, c)
	let decode4: tuple4<'a, 'b, 'c, 'd> => ('a, 'b, 'c, 'd) = ((a, (b, (c, (d, ()))))) => (a, b, c, d)
	let decode5: tuple5<'a, 'b, 'c, 'd, 'e> => ('a, 'b, 'c, 'd, 'e) = ((a, (b, (c, (d, (e, ())))))) => (a, b, c, d, e)
	let decode6: tuple6<'a, 'b, 'c, 'd, 'e, 'f> => ('a, 'b, 'c, 'd, 'e, 'f) = ((a, (b, (c, (d, (e, (f, ()))))))) => (a, b, c, d, e, f)
	let decode7: tuple7<'a, 'b, 'c, 'd, 'e, 'f, 'g> => ('a, 'b, 'c, 'd, 'e, 'f, 'g) = ((a, (b, (c, (d, (e, (f, (g, ())))))))) => (a, b, c, d, e, f, g)

	// Some weird ones:
	let return1: ('a) => tuple1<'a> = (a) => (a, ())
  let return2: ('a) => tuple2<'a, 'a> = (a) => (a, return1(a))
	let return3: ('a) => tuple3<'a, 'a, 'a> = (a) => (a, return2(a))
	let return4: ('a) => tuple4<'a, 'a, 'a, 'a> = (a) => (a, return3(a))
	let return5: ('a) => tuple5<'a, 'a, 'a, 'a, 'a> = (a) => (a, return4(a))
	let return6: ('a) => tuple6<'a, 'a, 'a, 'a, 'a, 'a> = (a) => (a, return5(a))
	let return7: ('a) => tuple7<'a, 'a, 'a, 'a, 'a, 'a, 'a> = (a) => (a, return6(a))

	let toList1: tuple1<'a> => array<'a> = ((a, ())) => [a]
	let toList2: tuple2<'a, 'a> => array<'a> = ((a, (b, ()))) => [a, b]
	let toList3: tuple3<'a, 'a, 'a> => array<'a> = ((a, (b, (c, ())))) => [a, b, c]
	let toList4: tuple4<'a, 'a, 'a, 'a> => array<'a> = ((a, (b, (c, (d, ()))))) => [a, b, c, d]
	let toList5: tuple5<'a, 'a, 'a, 'a, 'a> => array<'a> = ((a, (b, (c, (d, (e, ())))))) => [a, b, c, d, e]
	let toList6: tuple6<'a, 'a, 'a, 'a, 'a, 'a> => array<'a> = ((a, (b, (c, (d, (e, (f, ()))))))) => [a, b, c, d, e, f]
	let toList7: tuple7<'a, 'a, 'a, 'a, 'a, 'a, 'a> => array<'a> = ((a, (b, (c, (d, (e, (f, (g, ())))))))) => [a, b, c, d, e, f, g]

	let napply1: (tuple1<'a>, tuple1<'a => 'ao>) => tuple1<'ao> = ((a, ()), (f, ())) => tuple1(f(a))
	let napply2: (tuple2<'a, 'b>, tuple2<'a => 'ao, 'b => 'bo>) => tuple2<'ao, 'bo> = ((a, (b, ())), (f, (g, ()))) => tuple2(f(a), g(b))
	let napply3: (tuple3<'a, 'b, 'c>, tuple3<'a => 'ao, 'b => 'bo, 'c => 'co>) => tuple3<'ao, 'bo, 'co> = ((a, (b, (c, ()))), (f, (g, (h, ())))) => tuple3(f(a), g(b), h(c))
	let napply4: (tuple4<'a, 'b, 'c, 'd>, tuple4<'a => 'ao, 'b => 'bo, 'c => 'co, 'd => 'do>) => tuple4<'ao, 'bo, 'co, 'do> = ((a, (b, (c, (d, ())))), (f, (g, (h, (i, ()))))) => tuple4(f(a), g(b), h(c), i(d))
	let napply5: (tuple5<'a, 'b, 'c, 'd, 'e>, tuple5<'a => 'ao, 'b => 'bo, 'c => 'co, 'd => 'do, 'e => 'eo>) => tuple5<'ao, 'bo, 'co, 'do, 'eo> = ((a, (b, (c, (d, (e, ()))))) , (f, (g, (h, (i, (j, ())))))) => tuple5(f(a), g(b), h(c), i(d), j(e))
	let napply6: (tuple6<'a, 'b, 'c, 'd, 'e, 'f>, tuple6<'a => 'ao, 'b => 'bo, 'c => 'co, 'd => 'do, 'e => 'eo, 'f => 'fo>) => tuple6<'ao, 'bo, 'co, 'do, 'eo, 'fo> = ((a, (b, (c, (d, (e, (f, ())))))), (g, (h, (i, (j, (k, (l, ()))))))) => tuple6(g(a), h(b), i(c), j(d), k(e), l(f))
	let napply7: (tuple7<'a, 'b, 'c, 'd, 'e, 'f, 'g>, tuple7<'a => 'ao, 'b => 'bo, 'c => 'co, 'd => 'do, 'e => 'eo, 'f => 'fo, 'g => 'go>) => tuple7<'ao, 'bo, 'co, 'do, 'eo, 'fo, 'go> = ((a, (b, (c, (d, (e, (f, (g, ()))))))), (h, (i, (j, (k, (l, (m, (n, ())))))))) => tuple7(h(a), i(b), j(c), k(d), l(e), m(f), n(g))

	// Package as modules for application to other functors
	// module Tuple1 = {
	// 	type t<'a> = tuple1<'a>
	// 	let make = tuple1
	// 	let uncurry = uncurry1
	// 	let curry = curry1
	// 	let encode = (a) => 
	// 	let return = return1
	// 	let toList = toList1
	// 	let napply = napply1

	// 	// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
	// 	let mono = (f, t) => napply(f, t)->toList
	// 	let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
	// 	let some = (f, t) => napply(f, t)->toList->Array.some(x => x)
	// }

	module Tuple2 = {
		type t<'a, 'b> = tuple2<'a, 'b>
		let make = tuple2
		let uncurry = uncurry2
		let curry = curry2
		let return = return2
		let toList = toList2
		let napply = napply2
		
		// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
		let encode = encode2
		let decode = decode2
		let mono = (f, t) => napply(f, t)->toList
		let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
		let some = (f, t) => napply(f, t)->toList->Array.some(x => x)

	}

	module Tuple3 = {
		type t<'a, 'b, 'c> = tuple3<'a, 'b, 'c>
		let make = tuple3
		let uncurry = uncurry3
		let curry = curry3
		let return = return3
		let toList = toList3
		let napply = napply3
		
		// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
		let encode = encode3
		let decode = decode3
		let mono = (f, t) => napply(f, t)->toList
		let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
		let some = (f, t) => napply(f, t)->toList->Array.some(x => x)

	}

	module Tuple4 = {
		type t<'a, 'b, 'c, 'd> = tuple4<'a, 'b, 'c, 'd>
		let make = tuple4
		let uncurry = uncurry4
		let curry = curry4
		let return = return4
		let toList = toList4
		let napply = napply4
		
		// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
		let encode = encode4
		let decode = decode4
		let mono = (f, t) => napply(f, t)->toList
		let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
		let some = (f, t) => napply(f, t)->toList->Array.some(x => x)

	}

	module Tuple5 = {
		type t<'a, 'b, 'c, 'd, 'e> = tuple5<'a, 'b, 'c, 'd, 'e>
		let make = tuple5
		let uncurry = uncurry5
		let curry = curry5
		let return = return5
		let toList = toList5
		let napply = napply5
		
		// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
		let encode = encode5
		let decode = decode5
		let mono = (f, t) => napply(f, t)->toList
		let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
		let some = (f, t) => napply(f, t)->toList->Array.some(x => x)

	}

	module Tuple6 = {
		type t<'a, 'b, 'c, 'd, 'e, 'f> = tuple6<'a, 'b, 'c, 'd, 'e, 'f>
		let make = tuple6
		let uncurry = uncurry6
		let curry = curry6
		let return = return6
		let toList = toList6
		let napply = napply6
		
		// Conveniences. Need to be done literally here to avoid  mutation/side-effect error
		let encode = encode6
		let decode = decode6
		let mono = (f, t) => napply(f, t)->toList
		let all = (f, t) => napply(f, t)->toList->Array.all(x => x)
		let some = (f, t) => napply(f, t)->toList->Array.some(x => x)
	}
}
