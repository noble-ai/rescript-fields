@deriving(accessors)
type t<'pack> = { pack: 'pack, close: () => () }

let map = (c, fn) => {
	pack: c.pack->fn,
	close: c.close
}