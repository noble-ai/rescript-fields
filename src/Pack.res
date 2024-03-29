@@ocaml.doc("In traversing a field tree, it gets painful to manage adjusting your field type and the change nesting in parallel.
	but we know enough in fields to do that parallel partition for you.
	this type then contains a field and actions appropriate for one level in the tree.
	onChange also included in cases where you have a change directly at the level of this field
	and havnt yet or cant convert to actions. I go back and forth about functionalalizing. but the deeply nested change typese
	were hard for people to reason about....")

type t<'f, 'change, 'actions, 'actions_> = {
	field: 'f,
	@ocaml("take a change at the level of this field, in case you are still dealing with changes/onChange trees, prefer actions?")
	onChange: 'change => unit,
	@ocaml.doc("intended as an actions record returning Promise<()>, for when you have multiple simultaneous changes, and fields handling of that is still broken")
	actions: 'actions,
	@ocaml.doc("intended as an actions record returning (), for when you are emitting a change from a leaf handler often. and ideally all the time if fields handling of simultaneous changes is fixed")
	actions_: 'actions_
}