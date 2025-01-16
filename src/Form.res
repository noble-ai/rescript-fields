@@ocaml.doc("In traversing a field tree, it gets painful to manage adjusting your field type and the change nesting in parallel.
	but we know enough in fields to do that parallel partition for you.
	this type then contains a field and actions appropriate for one level in the tree.
	onChange also included in cases where you have a change directly at the level of this field
	and havnt yet or cant convert to actions. I go back and forth about functionalalizing. but the deeply nested change typese
	were hard for people to reason about....")

@deriving(accessors)
type t<'f, 'actions> = {
	field: 'f,
	@ocaml.doc("intended as an actions record returning ()")
	actions: 'actions,
}

let setField = ({actions}: t<'a, 'b>, field) => {field, actions}
let setActions = ({field}: t<'a, 'b>, actions) => {field, actions}

let bimap = ({field, actions}, f, g) => {
	{field: f(field), actions: g(actions)}
}