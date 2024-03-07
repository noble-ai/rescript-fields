# Field


\nThis module type describes the requirements for a Field module\nYou'll see this Field.T in the Module Functions which asserts\nthat a module passed to the function has each of these types and values.\n

### Field.T
  
  
### Field.T.context
  
`type context`  


### Field.T.input
  
`type input`  


### Field.T.showInput
  
`let showInput: input => string`  


### Field.T.output
  
`type output`  


### Field.T.error
  
`type error`  


### Field.T.inner
  
`type inner`  


### Field.T.t
  
`type t`  


### Field.T.empty
  
`let empty: context => inner`  


### Field.T.init
  
`let init: context => t`  


### Field.T.set
  
`let set: input => t`  


### Field.T.validate
  
`let validate: (bool, context, t) => Dynamic.t<t>`  


### Field.T.change
  
`type change`  


### Field.T.actions
  
`type actions`  


### Field.T.actions
  
`let actions: actions`  


### Field.T.makeSet
  
`let makeSet: input => change`  


### Field.T.showChange
  
`let showChange: change => string`  


### Field.T.reduce
  
`let reduce: (
  ~context: context,
  Dynamic.t<t>,
  Indexed.t<change>,
) => Dynamic.t<t>`  


### Field.T.inner
  
`let inner: t => inner`  


### Field.T.input
  
`let input: t => input`  


### Field.T.output
  
`let output: t => option<output>`  


### Field.T.error
  
`let error: t => option<error>`  


### Field.T.enum
  
`let enum: t => Store.enum`  


### Field.T.show
  
`let show: t => string`  


### Field.T.printError
  
`let printError: t => option<string>`  


### Field.printErrorArray
  
`let printErrorArray: Array.t<option<string>> => option<string>`  


### Field.setOrClear
  
`let setOrClear: option<'a> => [> #Clear | #Set('a)]`  

