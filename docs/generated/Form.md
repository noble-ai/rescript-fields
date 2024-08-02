# Form


In traversing a field tree, it gets painful to manage adjusting your field type and the change nesting in parallel.  
	but we know enough in fields to do that parallel partition for you.  
	this type then contains a field and actions appropriate for one level in the tree.  
	onChange also included in cases where you have a change directly at the level of this field  
	and havnt yet or cant convert to actions. I go back and forth about functionalalizing. but the deeply nested change typese  
	were hard for people to reason about....

### Form.t
  
`type t<'f, 'actions> = {field: 'f, actions: 'actions}`  


### Form.field
  
`let field: t<'f, 'actions> => 'f`  


### Form.actions
  
`let actions: t<'f, 'actions> => 'actions`  


### Form.bimap
  
`let bimap: (t<'a, 'b>, 'a => 'c, 'b => 'd) => t<'c, 'd>`  

