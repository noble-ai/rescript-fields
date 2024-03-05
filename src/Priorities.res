// Priorities used to track Field changes and prevent later changes of lesser importance from overwriting earlier more important ones
// Lower number means higher priority

type t<'v> = Map.t<int, 'v>
let empty = Map.make
let apply = Map.set

// Get highest index for all priorities higher (closer to 0) than p
let get = (t: t<int>, p: int) => {
	Array.range(p)
	->Array.Mut.reverse
	->Array.map(x => x->Map.get(t, _)->Option.or(-1))
	->Array.reduce(Int.max, -1)
	->Option.predicate(x => x >= 0)
} 
