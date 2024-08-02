# FieldCheck




### FieldCheck.context
  
`type context = unit`  


### FieldCheck.input
  
`type input = bool`  


### FieldCheck.showInput
  
`let showInput: input => string`  


### FieldCheck.output
  
`type output = bool`  


### FieldCheck.error
  
`type error = unit`  


### FieldCheck.inner
  
`type inner = bool`  


### FieldCheck.t
  
`type t = Store.t<inner, output, error>`  


### FieldCheck.empty
  
`let empty: 'a => bool`  


### FieldCheck.init
  
`let init: 'a => Store.t<bool, 'b, 'c>`  


### FieldCheck.set
  
`let set: 'a => Store.t<'a, 'a, 'b>`  


### FieldCheck.validate
  
`let validate: ('a, context, t) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>`  


### FieldCheck.actions
  
`type actions<'change> = {set: input => 'change}`  


### FieldCheck.mapActions
  
`let mapActions: (actions<'a>, 'a => 'b) => actions<'b>`  


### FieldCheck.makeDyn
  
`let makeDyn: (
  context,
  option<input>,
  Rxjs.Observable.t<input>,
  option<Rxjs.Observable.t<unit>>,
) => Dyn.t<Close.t<Form.t<t, actions<unit>>>>`  


### FieldCheck.inner
  
`let inner: Store.t<'a, 'b, 'c> => 'a`  


### FieldCheck.input
  
`let input: Store.t<'a, 'b, 'c> => 'a`  


### FieldCheck.output
  
`let output: Store.t<'a, 'b, 'c> => option<'b>`  


### FieldCheck.error
  
`let error: Store.t<'a, 'b, 'c> => option<'c>`  


### FieldCheck.enum
  
`let enum: Store.t<'a, 'b, 'c> => Store.enum`  


### FieldCheck.show
  
`let show: t => string`  


### FieldCheck.printError
  
`let printError: t => option<'a>`  

