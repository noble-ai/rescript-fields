@deriving(accessors)
type t<'a> = {
	value: 'a,
	index: int,
	priority: int
}

let map = (t: t<'a>, f: 'a => 'b): t<'b> => {
	...t,
	value: f(t.value),
}

let const = (t: t<'a>, value: 'v): t<'v> => {
	...t,
	value
}

// For use in reduce
let latest = (a: int, b: t<'b>) => Int.max(a, b.index)
let highest = (a: int, b: t<'b>) => Int.max(a, b.priority)

// TODO: is map/traverse? - AxM
let overValue = (t: t<'a>, f: 'a => option<'b>): option<t<'b>> => {
	t.value->f->Option.map(value => {...t, value})
}

let overValue2 = (f, t) => overValue(t, f)

