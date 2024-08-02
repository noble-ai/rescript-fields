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
  
`type t<'e, 'v, 'i> = {
  empty?: 'e,
  validate?: 'v,
  inner: 'i,
  validateImmediate?: bool,
}`  


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


### FieldVector.Actions
  
  
### FieldVector.Actions.t
  
`type t<'input, 'change, 'inner> = {
  set: 'input => 'change,
  clear: unit => 'change,
  opt: option<'input> => 'change,
  inner: 'inner,
  validate: unit => 'change,
}`  


### FieldVector.Actions.trimap
  
`let trimap: (
  t<'a, 'b, 'c>,
  'd => 'a,
  'b => 'e,
  'c => 'f,
) => t<'d, 'e, 'f>`  


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


### FieldVector.Tail
  
  
### FieldVector.Tail.contextInner
  
`type contextInner`  


### FieldVector.Tail.context
  
`type context`  


### FieldVector.Tail.input
  
`type input`  


### FieldVector.Tail.t
  
`type t`  


### FieldVector.Tail.inner
  
`type inner`  


### FieldVector.Tail.output
  
`type output`  


### FieldVector.Tail.showInput
  
`let showInput: input => string`  


### FieldVector.Tail.inner
  
`let inner: t => inner`  


### FieldVector.Tail.set
  
`let set: input => t`  


### FieldVector.Tail.emptyInner
  
`let emptyInner: contextInner => inner`  


### FieldVector.Tail.empty
  
`let empty: context => inner`  


### FieldVector.Tail.hasEnum
  
`let hasEnum: (inner, Store.enum) => bool`  


### FieldVector.Tail.toResultInner
  
`let toResultInner: inner => result<output, Store.enum>`  


### FieldVector.Tail.validateInner
  
`let validateInner: (
  contextInner,
  inner,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, inner>`  


### FieldVector.Tail.actionsInner
  
`type actionsInner<'change>`  


### FieldVector.Tail.mapActionsInner
  
`let mapActionsInner: (actionsInner<'change>, 'change => 'b) => actionsInner<'b>`  


### FieldVector.Tail.partition
  
`type partition`  
partition is opaque here but will be a composition of Form.t

### FieldVector.Tail.splitInner
  
`let splitInner: (inner, actionsInner<unit>) => partition`  


### FieldVector.Tail.makeDynInner
  
`let makeDynInner: (
  contextInner,
  option<input>,
  Rxjs.Observable.t<input>,
) => Dyn.t<Close.t<Form.t<inner, actionsInner<unit>>>>`  


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


### FieldVector.Vector0.emptyInner
  
`let emptyInner: contextInner => inner`  


### FieldVector.Vector0.empty
  
`let empty: contextInner => inner`  


### FieldVector.Vector0.initInner
  
`let initInner: unit => unit`  


### FieldVector.Vector0.init
  
`let init: unit => Store.t<unit, unit, 'a>`  


### FieldVector.Vector0.hasEnum
  
`let hasEnum: ('a, [> #Valid]) => bool`  


### FieldVector.Vector0.toResultInner
  
`let toResultInner: unit => result<output, Store.enum>`  


### FieldVector.Vector0.validateInner
  
`let validateInner: ('a, inner) => Rxjs.t<Rxjs.foreign, Rxjs.void, inner>`  


### FieldVector.Vector0.validate
  
`let validate: ('a, context, t) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>`  


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


### FieldVector.Vector0.actionsInner
  
`type actionsInner<'change> = unit`  


### FieldVector.Vector0.mapActionsInner
  
`let mapActionsInner: ('a, 'b) => unit`  


### FieldVector.Vector0.actions
  
`type actions<'change> = Actions.t<
  input,
  'change,
  actionsInner<'change>,
>`  


### FieldVector.Vector0.mapActions
  
`let mapActions: (Actions.t<'a, 'b, 'c>, 'c => 'd) => Actions.t<'a, unit, 'd>`  


### FieldVector.Vector0.partition
  
`type partition = unit`  


### FieldVector.Vector0.splitInner
  
`let splitInner: ('a, 'b) => unit`  


### FieldVector.Vector0.makeDynInner
  
`let makeDynInner: (
  contextInner,
  option<input>,
  Rxjs.Observable.t<input>,
) => Dyn.t<Close.t<Form.t<inner, actionsInner<unit>>>>`  


### FieldVector.Vector0.makeDyn
  
`let makeDyn: (
  context,
  option<input>,
  Rxjs.Observable.t<input>,
  option<Rxjs.Observable.t<unit>>,
) => Dyn.t<Close.t<Form.t<t, actions<unit>>>>`  


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


### FieldVector.VectorRec.Make.emptyInner
  
`let emptyInner: contextInner => inner`  


### FieldVector.VectorRec.Make.empty
  
`let empty: context => inner`  


### FieldVector.VectorRec.Make.init
  
`let init: context => Store.t<inner, 'a, 'b>`  


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
  ~validate: (inner, output) => Rxjs.t<
    Rxjs.foreign,
    Rxjs.void,
    t,
  >,
  inner,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>`  


### FieldVector.VectorRec.Make.validateInner
  
`let validateInner: (
  contextInner,
  inner,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, inner>`  


### FieldVector.VectorRec.Make.validateImpl
  
`let validateImpl: (context, t) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>`  


### FieldVector.VectorRec.Make.validate
  
`let validate: (bool, context, t) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>`  


### FieldVector.VectorRec.Make.actionsInner
  
`type actionsInner<'change> = (
  Head.actions<'change>,
  Tail.actionsInner<'change>,
)`  


### FieldVector.VectorRec.Make.mapActionsInner
  
`let mapActionsInner: (
  (Head.actions<'a>, Tail.actionsInner<'a>),
  'a => 'b,
) => (Head.actions<'b>, Tail.actionsInner<'b>)`  


### FieldVector.VectorRec.Make.actions
  
`type actions<'change> = Actions.t<
  input,
  'change,
  actionsInner<'change>,
>`  


### FieldVector.VectorRec.Make.mapActions
  
`let mapActions: (
  Actions.t<
    'a,
    'b,
    (Head.actions<'b>, Tail.actionsInner<'b>),
  >,
  'b => 'c,
) => Actions.t<
  'a,
  'c,
  (Head.actions<'c>, Tail.actionsInner<'c>),
>`  


### FieldVector.VectorRec.Make.partition
  
`type partition = (
  Form.t<Head.t, Head.actions<unit>>,
  Tail.partition,
)`  


### FieldVector.VectorRec.Make.splitInner
  
`let splitInner: (inner, actionsInner<unit>) => partition`  


### FieldVector.VectorRec.Make.split
  
`let split: Form.t<t, actions<unit>> => partition`  


### FieldVector.VectorRec.Make.logField
  
`let logField: Rxjs.t<
  'b,
  'c,
  Rxjs.t<'d, 'e, Close.t<Form.t<'t, 'a>>>,
> => Rxjs.t<'b, 'c, Rxjs.t<'d, 'e, Close.t<Form.t<'t, 'a>>>>`  


### FieldVector.VectorRec.Make.makeDynInner
  
`let makeDynInner: (
  contextInner,
  option<input>,
  Rxjs.Observable.t<input>,
) => Dyn.t<Close.t<Form.t<inner, actionsInner<unit>>>>`  


### FieldVector.VectorRec.Make.makeDyn
  
`let makeDyn: (
  context,
  option<input>,
  Rxjs.Observable.t<input>,
  option<Rxjs.Observable.t<unit>>,
) => Dyn.t<Close.t<Form.t<t, actions<unit>>>>`  


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
  

