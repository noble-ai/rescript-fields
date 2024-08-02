@@ocamldoc("A convenience for adding some nominative clarity to the pair of a pack and a close function.")

@deriving(accessors)
type t<'pack> = { pack: 'pack, close: () => () }

let map = (c, fn) => {
	pack: c.pack->fn,
	close: c.close
}