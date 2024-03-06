# FieldVector




### FieldVector.error
  
`type error = [#Part | #Whole(string)]`  


### FieldVector.resultValidate
  
`type resultValidate = Prelude.Promise.t<
  Prelude.Result.t<unit, string>,
>`  


### FieldVector.validateOut
  
`type validateOut<'out> = 'out => resultValidate`  


### FieldVector.Context
  
  
### FieldVector.Context.t
  
`type t<'e, 'v, 'i> = {empty?: 'e, validate?: 'v, inner: 'i}`  


### FieldVector.Context.empty
  
`let empty: t<'a, 'b, 'c> => option<'a>`  


### FieldVector.Context.validate
  
`let validate: t<'a, 'b, 'c> => option<'b>`  


### FieldVector.Context.inner
  
`let inner: t<'a, 'b, 'c> => 'c`  


### FieldVector.Context.trimap
  
`let trimap: (
  'a => 'b,
  'c => 'd,
  'e => 'f,
  t<'a, 'c, 'e>,
) => t<'b, 'd, 'f>`  


### FieldVector.Change
  
  
### FieldVector.Change.t
  
`type t<'input, 'inner> = [
  | #Clear
  | #Inner('inner)
  | #Set('input)
  | #Validate
]`  


### FieldVector.Change.makeSet
  
`let makeSet: 'a => [> #Set('a)]`  


### FieldVector.Change.bimap
  
`let bimap: (
  'a => 'b,
  'c => 'd,
  [< #Clear | #Inner('c) | #Set('a) | #Validate],
) => [> #Clear | #Inner('d) | #Set('b) | #Validate]`  


### FieldVector.Change.show
  
`let show: t<string, string> => string`  


### FieldVector.Actions
  
  
### FieldVector.Actions.t
  
`type t<'input, 'inner, 'actionsInner> = {
  set: 'input => Change.t<'input, 'inner>,
  clear: unit => Change.t<'input, 'inner>,
  inner: 'actionsInner,
  validate: unit => Change.t<'input, 'inner>,
}`  


### FieldVector.const
  
`let const: ('a => 'b, 'a, 'c) => 'b`  


### FieldVector.outputresult
  
`let outputresult: ('a => option<'b>, 'a => 'c, 'a) => result<'b, 'c>`  


### FieldVector.resolveErr
  
`let resolveErr: (
  'a,
  [< #Busy | #Dirty | #Init | #Invalid | #Valid],
) => Rxjs.t<
  Rxjs.foreign,
  Rxjs.void,
  Store.t<'a, 'b, [> #Part]>,
>`  


### FieldVector.Interface
  
  
### FieldVector.Interface.validateImmediate
  
`let validateImmediate: bool`  


### FieldVector.Tail
  
  
### FieldVector.Tail.contextInner
  
`type contextInner`  


### FieldVector.Tail.input
  
`type input`  


### FieldVector.Tail.inner
  
`type inner`  


### FieldVector.Tail.output
  
`type output`  


### FieldVector.Tail.t
  
`type t`  


### FieldVector.Tail.showInput
  
`let showInput: input => string`  


### FieldVector.Tail.inner
  
`let inner: t => inner`  


### FieldVector.Tail.set
  
`let set: input => t`  


### FieldVector.Tail.empty
  
`let empty: contextInner => inner`  


### FieldVector.Tail.hasEnum
  
`let hasEnum: (inner, Store.enum) => bool`  


### FieldVector.Tail.toResultInner
  
`let toResultInner: inner => result<output, Store.enum>`  


### FieldVector.Tail.validateInner
  
`let validateInner: (contextInner, inner) => Dynamic.t<inner>`  


### FieldVector.Tail.changeInner
  
`type changeInner`  


### FieldVector.Tail.showChangeInner
  
`let showChangeInner: changeInner => string`  


### FieldVector.Tail.actions
  
`type actions`  


### FieldVector.Tail.actions
  
`let actions: actions`  


### FieldVector.Tail.reduceChannel
  
`let reduceChannel: (
  ~contextInner: contextInner,
  Dynamic.t<inner>,
  Indexed.t<unit>,
  changeInner,
) => Dynamic.t<inner>`  


### FieldVector.Tail.reduceSet
  
`let reduceSet: (
  contextInner,
  Dynamic.t<inner>,
  Indexed.t<unit>,
  input,
) => Dynamic.t<inner>`  


### FieldVector.Tail.toInputInner
  
`let toInputInner: inner => input`  


### FieldVector.Tail.printErrorInner
  
`let printErrorInner: inner => array<option<string>>`  


### FieldVector.Tail.showInner
  
`let showInner: inner => array<string>`  


### FieldVector.Vector0
  
  
### FieldVector.Vector0.input
  
`type input = unit`  


### FieldVector.Vector0.inner
  
`type inner = unit`  


### FieldVector.Vector0.output
  
`type output = unit`  


### FieldVector.Vector0.error
  
`type error = error`  


### FieldVector.Vector0.t
  
`type t = Store.t<inner, output, error>`  


### FieldVector.Vector0.validate
  
`type validate = validateOut<output>`  


### FieldVector.Vector0.contextInner
  
`type contextInner = unit`  


### FieldVector.Vector0.context
  
`type context = unit`  


### FieldVector.Vector0.inputInner
  
`let inputInner: unit => unit`  


### FieldVector.Vector0.toInputInner
  
`let toInputInner: unit => unit`  


### FieldVector.Vector0.input
  
`let input: t => unit`  


### FieldVector.Vector0.showInput
  
`let showInput: unit => string`  


### FieldVector.Vector0.set
  
`let set: unit => t`  


### FieldVector.Vector0.empty
  
`let empty: unit => inner`  


### FieldVector.Vector0.initInner
  
`let initInner: unit => unit`  


### FieldVector.Vector0.init
  
`let init: unit => Store.t<unit, unit, 'a>`  


### FieldVector.Vector0.hasEnum
  
`let hasEnum: ('a, [> #Valid]) => bool`  


### FieldVector.Vector0.toResultInner
  
`let toResultInner: unit => result<output, Store.enum>`  


### FieldVector.Vector0.validateInner
  
`let validateInner: ('a, inner) => Dynamic.t<inner>`  


### FieldVector.Vector0.validate
  
`let validate: ('a, context, t) => Dynamic.t<t>`  


### FieldVector.Vector0.inner
  
`let inner: 'a => unit`  


### FieldVector.Vector0.showInner
  
`let showInner: 'a => array<'b>`  


### FieldVector.Vector0.enum
  
`let enum: 'a => [> #Valid]`  


### FieldVector.Vector0.output
  
`let output: 'a => unit`  


### FieldVector.Vector0.error
  
`let error: 'a => option<'b>`  


### FieldVector.Vector0.printErrorInner
  
`let printErrorInner: inner => array<option<string>>`  


### FieldVector.Vector0.printError
  
`let printError: t => option<string>`  


### FieldVector.Vector0.show
  
`let show: t => string`  


### FieldVector.Vector0.changeInner
  
`type changeInner = unit`  


### FieldVector.Vector0.showChangeInner
  
`let showChangeInner: changeInner => string`  


### FieldVector.Vector0.change
  
`type change = unit`  


### FieldVector.Vector0.showChange
  
`let showChange: unit => string`  


### FieldVector.Vector0.actions
  
`type actions = unit`  


### FieldVector.Vector0.toChange
  
`let toChange: ('a, 'b) => change`  


### FieldVector.Vector0.actions
  
`let actions: actions`  


### FieldVector.Vector0.reduceChannel
  
`let reduceChannel: (~contextInner: 'a, 'b, 'c, changeInner) => Dynamic.t<inner>`  


### FieldVector.Vector0.reduceSet
  
`let reduceSet: (
  'a,
  Dynamic.t<inner>,
  Indexed.t<unit>,
  'b,
) => Dynamic.t<inner>`  


### FieldVector.Vector0.reduce
  
`let reduce: (
  ~context: context,
  Dynamic.t<t>,
  Indexed.t<change>,
) => Dynamic.t<t>`  


### FieldVector.VectorRec
  
  
### FieldVector.VectorRec.Make
  
  
### FieldVector.VectorRec.Make.input
  
`type input = (Head.input, Tail.input)`  


### FieldVector.VectorRec.Make.inner
  
`type inner = (Head.t, Tail.inner)`  


### FieldVector.VectorRec.Make.output
  
`type output = (Head.output, Tail.output)`  


### FieldVector.VectorRec.Make.error
  
`type error = error`  


### FieldVector.VectorRec.Make.validate
  
`type validate = validateOut<output>`  


### FieldVector.VectorRec.Make.contextInner
  
`type contextInner = (Head.context, Tail.contextInner)`  


### FieldVector.VectorRec.Make.context
  
`type context = Context.t<input, validate, contextInner>`  


### FieldVector.VectorRec.Make.t
  
`type t = Store.t<inner, output, error>`  


### FieldVector.VectorRec.Make.showInput
  
`let showInput: input => string`  


### FieldVector.VectorRec.Make.set
  
`let set: input => t`  


### FieldVector.VectorRec.Make.empty
  
`let empty: contextInner => inner`  


### FieldVector.VectorRec.Make.init
  
`let init: contextInner => Store.t<inner, 'a, 'b>`  


### FieldVector.VectorRec.Make.validateOut
  
`let validateOut: (
  ~validate: option<output => Js.Promise.t<result<'a, 'b>>>,
  ~immediate: bool=?,
  inner,
  output,
) => Rxjs.t<
  Rxjs.foreign,
  Rxjs.void,
  Store.t<inner, output, [> #Whole('b)]>,
>`  


### FieldVector.VectorRec.Make.hasEnum
  
`let hasEnum: ((Head.t, Tail.inner), Store.enum) => bool`  


### FieldVector.VectorRec.Make.allResult
  
`let allResult: (
  (
    Prelude.Result.t<Head.output, Store.enum>,
    Prelude.Result.t<Tail.output, Store.enum>,
  ),
) => Prelude.Result.t<
  (Head.output, Tail.output),
  Store.enum,
>`  


### FieldVector.VectorRec.Make.toResultInner
  
`let toResultInner: inner => result<output, Store.enum>`  


### FieldVector.VectorRec.Make.makeStore
  
`let makeStore: (
  ~validate: (inner, output) => Dynamic.t<t>,
  inner,
) => Dynamic.t<t>`  


### FieldVector.VectorRec.Make.validateInner
  
`let validateInner: (contextInner, inner) => Dynamic.t<inner>`  


### FieldVector.VectorRec.Make.validateImpl
  
`let validateImpl: (context, t) => Dynamic.t<t>`  


### FieldVector.VectorRec.Make.validate
  
`let validate: (bool, context, t) => Dynamic.t<t>`  


### FieldVector.VectorRec.Make.changeInner
  
`type changeInner = Either.t<Head.change, Tail.changeInner>`  


### FieldVector.VectorRec.Make.showChangeInner
  
`let showChangeInner: changeInner => string`  


### FieldVector.VectorRec.Make.change
  
`type change = Change.t<input, changeInner>`  


### FieldVector.VectorRec.Make.makeSet
  
`let makeSet: 'a => [> #Set('a)]`  


### FieldVector.VectorRec.Make.showChange
  
`let showChange: change => string`  


### FieldVector.VectorRec.Make.actions
  
`type actions = (Head.change => change, Tail.actions)`  


### FieldVector.VectorRec.Make.actions
  
`let actions: actions`  


### FieldVector.VectorRec.Make.reduceField
  
`let reduceField: (
  Rxjs.t<'a, 'b, ('c, 'd)>,
  'e,
  (Rxjs.t<'a, 'b, 'c>, 'e) => Rxjs.t<'f, 'g, 'h>,
) => Rxjs.t<'f, 'g, ('h, 'd)>`  


### FieldVector.VectorRec.Make.reduceChannel
  
`let reduceChannel: (
  ~contextInner: contextInner,
  Rxjs.t<Rxjs.foreign, Rxjs.void, (Head.t, Tail.inner)>,
  Indexed.t<unit>,
  changeInner,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, (Head.t, Tail.inner)>`  


### FieldVector.VectorRec.Make.reduceSet
  
`let reduceSet: (
  contextInner,
  Dynamic.t<inner>,
  Indexed.t<unit>,
  (Head.input, Tail.input),
) => Dynamic.t<inner>`  


### FieldVector.VectorRec.Make.reduce
  
`let reduce: (
  ~context: context,
  Dynamic.t<t>,
  Indexed.t<change>,
) => Dynamic.t<t>`  


### FieldVector.VectorRec.Make.toInputInner
  
`let toInputInner: inner => (Head.input, Tail.input)`  


### FieldVector.VectorRec.Make.input
  
`let input: t => (Head.input, Tail.input)`  


### FieldVector.VectorRec.Make.inner
  
`let inner: Store.t<'a, 'b, 'c> => 'a`  


### FieldVector.VectorRec.Make.output
  
`let output: Store.t<'a, 'b, 'c> => option<'b>`  


### FieldVector.VectorRec.Make.error
  
`let error: Store.t<'a, 'b, 'c> => option<'c>`  


### FieldVector.VectorRec.Make.enum
  
`let enum: Store.t<'a, 'b, 'c> => Store.enum`  


### FieldVector.VectorRec.Make.printErrorInner
  
`let printErrorInner: inner => Array.t<option<string>>`  


### FieldVector.VectorRec.Make.printError
  
`let printError: t => option<string>`  


### FieldVector.VectorRec.Make.showInner
  
`let showInner: inner => Array.t<string>`  


### FieldVector.VectorRec.Make.show
  
`let show: t => string`  


### FieldVector.Vector1
  


### FieldVector.Vector2
  


### FieldVector.Vector3
  


### FieldVector.Vector4
  


### FieldVector.Vector5
  


### FieldVector.Vector6
  


### FieldVector.Vector7
  

