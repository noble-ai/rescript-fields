# FieldArray




### FieldArray.Context
  
  
### FieldArray.Context.structure
  
`type structure<'output, 'element, 'empty> = {
  validate?: array<'output> => Prelude.Promise.t<
    Prelude.Result.t<unit, string>,
  >,
  element: 'element,
  empty?: unit => array<'empty>,
  validateImmediate?: bool,
}`  


### FieldArray.length
  
`let length: (
  ~len: int,
  Array.t<'a>,
) => Prelude.Promise.t<result<unit, string>>`  


### FieldArray.IArray
  
  
### FieldArray.IArray.t
  
`type t`  


### FieldArray.IArray.filter
  
`let filter: array<t> => array<t>`  


### FieldArray.filterIdentity
  
`let filterIdentity: array<'a> => array<'a>`  


### FieldArray.filterGrace
  
`let filterGrace: array<'t> => Array.t<'t>`  


### FieldArray.actions
  
`type actions<'finput, 'factions, 'out> = {
  set: array<'finput> => 'out,
  add: option<'finput> => 'out,
  remove: int => 'out,
  opt: option<array<'finput>> => 'out,
  clear: unit => 'out,
  reset: unit => 'out,
  index: int => option<'factions>,
}`  


### FieldArray.T
  
  
### FieldArray.T.context
  
`type context`  


### FieldArray.T.input
  
`type input`  


### FieldArray.T.showInput
  
`let showInput: input => string`  


### FieldArray.T.output
  
`type output`  


### FieldArray.T.error
  
`type error`  


### FieldArray.T.inner
  
`type inner`  


### FieldArray.T.t
  
`type t`  


### FieldArray.T.empty
  
`let empty: context => inner`  


### FieldArray.T.init
  
`let init: context => t`  


### FieldArray.T.set
  
`let set: input => t`  


### FieldArray.T.validate
  
`let validate: (bool, context, t) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>`  


### FieldArray.T.actions
  
`type actions<'change>`  


### FieldArray.T.mapActions
  
`let mapActions: (actions<'change>, 'change => 'b) => actions<'b>`  


### FieldArray.T.makeDyn
  
`let makeDyn: (
  context,
  option<input>,
  Rxjs.Observable.t<input>,
  option<Rxjs.Observable.t<unit>>,
) => Dyn.t<Close.t<Form.t<t, actions<unit>>>>`  


### FieldArray.T.inner
  
`let inner: t => inner`  


### FieldArray.T.input
  
`let input: t => input`  


### FieldArray.T.output
  
`let output: t => option<output>`  


### FieldArray.T.error
  
`let error: t => option<error>`  


### FieldArray.T.enum
  
`let enum: t => Store.enum`  


### FieldArray.T.show
  
`let show: t => string`  


### FieldArray.T.printError
  
`let printError: t => option<string>`  


### FieldArray.T.inputElement
  
`type inputElement`  


### FieldArray.T.parted
  
`type parted`  


### FieldArray.T.split
  
`let split: Form.t<t, actions<unit>> => parted`  


### FieldArray.error
  
`type error = [#Part | #Whole(string)]`  


### FieldArray.Make
  
  
### FieldArray.Make.context
  
`type context = Context.structure<
  F.output,
  F.context,
  F.input,
>`  


### FieldArray.Make.input
  
`type input = array<F.input>`  


### FieldArray.Make.showInput
  
`let showInput: input => string`  


### FieldArray.Make.output
  
`type output = array<F.output>`  


### FieldArray.Make.error
  
`type error = error`  


### FieldArray.Make.inner
  
`type inner = array<F.t>`  


### FieldArray.Make.t
  
`type t = Store.t<array<F.t>, array<F.output>, error>`  


### FieldArray.Make.empty
  
`let empty: context => inner`  


### FieldArray.Make.init
  
`let init: context => t`  


### FieldArray.Make.set
  
`let set: input => t`  


### FieldArray.Make.validate
  
`let validate: (bool, context, t) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>`  


### FieldArray.Make.actions
  
`type actions<'change> = actions<
  F.input,
  F.actions<'change>,
  'change,
>`  


### FieldArray.Make.mapActions
  
`let mapActions: (actions<'change>, 'change => 'b) => actions<'b>`  


### FieldArray.Make.makeDyn
  
`let makeDyn: (
  context,
  option<input>,
  Rxjs.Observable.t<input>,
  option<Rxjs.Observable.t<unit>>,
) => Dyn.t<Close.t<Form.t<t, actions<unit>>>>`  


### FieldArray.Make.inner
  
`let inner: t => inner`  


### FieldArray.Make.input
  
`let input: t => input`  


### FieldArray.Make.output
  
`let output: t => option<output>`  


### FieldArray.Make.error
  
`let error: t => option<error>`  


### FieldArray.Make.enum
  
`let enum: t => Store.enum`  


### FieldArray.Make.show
  
`let show: t => string`  


### FieldArray.Make.printError
  
`let printError: t => option<string>`  


### FieldArray.Make.inputElement
  
`type inputElement = F.input`  


### FieldArray.Make.parted
  
`type parted = array<Form.t<F.t, F.actions<unit>>>`  


### FieldArray.Make.split
  
`let split: Form.t<t, actions<unit>> => parted`  

