# FieldChoice




### FieldChoice.Make
  
  
### FieldChoice.Make.context
  
`type context = array<T.t>`  


### FieldChoice.Make.input
  
`type input = T.t`  


### FieldChoice.Make.output
  
`type output = T.t`  


### FieldChoice.Make.error
  
`type error = unit`  


### FieldChoice.Make.inner
  
`type inner = T.t`  


### FieldChoice.Make.t
  
`type t = Store.t<inner, output, error>`  


### FieldChoice.Make.empty
  
`let empty: Array.t<'a> => 'a`  


### FieldChoice.Make.init
  
`let init: context => Store.t<T.t, 'a, 'b>`  


### FieldChoice.Make.set
  
`let set: 'a => Store.t<'a, 'b, 'c>`  


### FieldChoice.Make.validate
  
`let validate: (~force: bool=?, 'a, t) => Dynamic.t<t>`  


### FieldChoice.Make.change
  
`type change = T.t`  


### FieldChoice.Make.reduce
  
`let reduce: (~context: context, t, Indexed.t<change>) => Dynamic.t<t>`  


### FieldChoice.Make.enum
  
`let enum: Store.t<'a, 'b, 'c> => Store.enum`  


### FieldChoice.Make.inner
  
`let inner: Store.t<'a, 'b, 'c> => 'a`  


### FieldChoice.Make.input
  
`let input: Store.t<'a, 'b, 'c> => 'a`  


### FieldChoice.Make.error
  
`let error: Store.t<'a, 'b, 'c> => option<'c>`  


### FieldChoice.Make.output
  
`let output: Store.t<'a, 'b, 'c> => option<'b>`  


### FieldChoice.Make.printError
  
`let printError: 'a => option<'b>`  

