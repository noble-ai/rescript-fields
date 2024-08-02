# Field


  
This module type describes the requirements for a Field module  
You'll see this Field.T in the Module Functions which asserts  
that a module passed to the function has each of these types and values.  


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
  
`let validate: (bool, context, t) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>`  


### Field.T.actions
  
`type actions<'change>`  


### Field.T.mapActions
  
`let mapActions: (actions<'change>, 'change => 'b) => actions<'b>`  


### Field.T.makeDyn
  
`let makeDyn: (
  context,
  option<input>,
  Rxjs.Observable.t<input>,
  option<Rxjs.Observable.t<unit>>,
) => Dyn.t<Close.t<Form.t<t, actions<unit>>>>`  


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

