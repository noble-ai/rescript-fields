# Close




### Close.t
  
`type t<'pack> = {pack: 'pack, close: unit => unit}`  


### Close.pack
  
`let pack: t<'pack> => 'pack`  


### Close.close
  
`let close: (t<'pack>, unit) => unit`  


### Close.map
  
`let map: (t<'a>, 'a => 'b) => t<'b>`  

# Dyn




### Dyn.dyn
  
`type dyn<'a> = Rxjs.Observable.t<Rxjs.Observable.t<'a>>`  


### Dyn.t
  
`type t<'a> = {first: 'a, dyn: dyn<'a>}`  


### Dyn.first
  
`let first: t<'a> => 'a`  


### Dyn.dyn
  
`let dyn: t<'a> => dyn<'a>`  


### Dyn.map
  
`let map: (t<'a>, 'a => 'b) => t<'b>`  

# Dynamic




### Dynamic.return
  
`let return: 'a => Rxjs.t<Rxjs.foreign, Rxjs.void, 'a>`  


### Dynamic.fromPromise
  
`let fromPromise: Js.Promise.t<'a> => Rxjs.t<Rxjs.foreign, Rxjs.void, 'a>`  


### Dynamic.toPromise
  
`let toPromise: Rxjs.t<'a, 'b, 'c> => Js.Promise.t<'c>`  


### Dynamic.toHistory
  
`let toHistory: Rxjs.t<'c, 's, 'out> => Js.Promise.t<Array.t<'out>>`  


### Dynamic.startWith
  
`let startWith: (Rxjs.t<'a, 'b, 'c>, 'c) => Rxjs.t<'a, 'b, 'c>`  


### Dynamic.combineLatest
  
`let combineLatest: array<
  Rxjs.t<Rxjs.foreign, Rxjs.void, 'a>,
> => Rxjs.t<Rxjs.foreign, Rxjs.void, array<'a>>`  


### Dynamic.combineLatest2
  
`let combineLatest2: (
  (Rxjs.t<'a, 'b, 'c>, Rxjs.t<'d, 'e, 'f>),
) => Rxjs.t<Rxjs.foreign, Rxjs.void, ('c, 'f)>`  


### Dynamic.combineLatest3
  
`let combineLatest3: (
  (
    Rxjs.t<'a, 'b, 'c>,
    Rxjs.t<'d, 'e, 'f>,
    Rxjs.t<'g, 'h, 'i>,
  ),
) => Rxjs.t<Rxjs.foreign, Rxjs.void, ('c, 'f, 'i)>`  


### Dynamic.combineLatest4
  
`let combineLatest4: (
  (
    Rxjs.t<'a, 'b, 'c>,
    Rxjs.t<'d, 'e, 'f>,
    Rxjs.t<'g, 'h, 'i>,
    Rxjs.t<'j, 'k, 'l>,
  ),
) => Rxjs.t<Rxjs.foreign, Rxjs.void, ('c, 'f, 'i, 'l)>`  


### Dynamic.combineLatest5
  
`let combineLatest5: (
  (
    Rxjs.t<'a, 'b, 'c>,
    Rxjs.t<'d, 'e, 'f>,
    Rxjs.t<'g, 'h, 'i>,
    Rxjs.t<'j, 'k, 'l>,
    Rxjs.t<'m, 'n, 'o>,
  ),
) => Rxjs.t<Rxjs.foreign, Rxjs.void, ('c, 'f, 'i, 'l, 'o)>`  


### Dynamic.combineLatest6
  
`let combineLatest6: (
  (
    Rxjs.t<'a, 'b, 'c>,
    Rxjs.t<'d, 'e, 'f>,
    Rxjs.t<'g, 'h, 'i>,
    Rxjs.t<'j, 'k, 'l>,
    Rxjs.t<'m, 'n, 'o>,
    Rxjs.t<'p, 'q, 'r>,
  ),
) => Rxjs.t<
  Rxjs.foreign,
  Rxjs.void,
  ('c, 'f, 'i, 'l, 'o, 'r),
>`  


### Dynamic.map
  
`let map: (Rxjs.t<'a, 'b, 'c>, 'c => 'd) => Rxjs.t<'a, 'b, 'd>`  


### Dynamic.mapi
  
`let mapi: (Rxjs.t<'a, 'b, 'c>, ('c, int) => 'd) => Rxjs.t<'a, 'b, 'd>`  


### Dynamic.const
  
`let const: (Rxjs.t<'a, 'b, 'c>, 'd) => Rxjs.t<'a, 'b, 'd>`  


### Dynamic.bind
  
`let bind: (
  Rxjs.t<'ca, 'sa, 'out>,
  'out => Rxjs.t<Rxjs.foreign, Rxjs.void, 'b>,
) => Rxjs.t<'ca, 'sa, 'b>`  


### Dynamic.merge
  
`let merge: (
  Rxjs.t<'ca, 'sa, 'a>,
  'a => Rxjs.t<Rxjs.foreign, Rxjs.void, 'b>,
) => Rxjs.t<'ca, 'sa, 'b>`  


### Dynamic.switchMap
  
`let switchMap: (
  Rxjs.t<'ca, 'sa, 'a>,
  'a => Rxjs.t<Rxjs.foreign, Rxjs.void, 'b>,
) => Rxjs.t<'ca, 'sa, 'b>`  


### Dynamic.switchSequence
  
`let switchSequence: Rxjs.t<'a, 'b, Rxjs.t<'c, 'd, 'e>> => Rxjs.t<'a, 'b, 'e>`  


### Dynamic.tap
  
`let tap: (Rxjs.t<'a, 'b, 'c>, 'c => unit) => Rxjs.t<'a, 'b, 'c>`  


### Dynamic.tap_
  
`let tap_: (Rxjs.t<'a, 'b, 'c>, 'c => unit) => unit`  


### Dynamic.filter
  
`let filter: (Rxjs.t<'a, 'b, 'c>, 'c => bool) => Rxjs.t<'a, 'b, 'c>`  


### Dynamic.finalize
  
`let finalize: (Rxjs.t<'a, 'b, 'c>, unit => unit) => Rxjs.t<'a, 'b, 'c>`  


### Dynamic.finally
  
`let finally: (Rxjs.t<'a, 'b, 'c>, 'c => unit) => unit`  


### Dynamic.withLatestFrom
  
`let withLatestFrom: (
  Rxjs.t<'a, 'b, 'c>,
  Rxjs.t<'d, 'e, 'f>,
) => Rxjs.t<'a, 'b, ('c, 'f)>`  


### Dynamic.withLatestFrom2
  
`let withLatestFrom2: (
  Rxjs.t<'a, 'b, 'c>,
  Rxjs.t<'d, 'e, 'f>,
  Rxjs.t<'g, 'h, 'i>,
) => Rxjs.t<'a, 'b, ('c, 'f, 'i)>`  


### Dynamic.take
  
`let take: (Rxjs.t<'a, 'b, 'c>, int) => Rxjs.t<'a, 'b, 'c>`  


### Dynamic.keepMap
  
`let keepMap: (Rxjs.t<'a, 'b, 'c>, 'c => option<'d>) => Rxjs.t<'a, 'b, 'd>`  


### Dynamic.contramap
  
`let contramap: (Rxjs.Observer.t<'a>, 'b => 'a) => Rxjs.Observer.t<'b>`  


### Dynamic.contrafilter
  
`let contrafilter: (
  Rxjs.Observer.t<'a>,
  'b => option<'a>,
) => Rxjs.Observer.t<'b>`  


### Dynamic.contraCatOptions
  
`let contraCatOptions: Rxjs.Observer.t<'a> => Rxjs.Observer.t<option<'a>>`  


### Dynamic.partition2
  
`let partition2: (
  Rxjs.t<'a, 'b, 'c>,
  ('c => option<'d>, 'c => option<'e>),
) => (Rxjs.t<'a, 'b, 'd>, Rxjs.t<'a, 'b, 'e>)`  


### Dynamic.partition3
  
`let partition3: (
  Rxjs.t<'a, 'b, 'c>,
  ('c => option<'d>, 'c => option<'e>, 'c => option<'f>),
) => (
  Rxjs.t<'a, 'b, 'd>,
  Rxjs.t<'a, 'b, 'e>,
  Rxjs.t<'a, 'b, 'f>,
)`  


### Dynamic.partition4
  
`let partition4: (
  Rxjs.t<'a, 'b, 'c>,
  (
    'c => option<'d>,
    'c => option<'e>,
    'c => option<'f>,
    'c => option<'g>,
  ),
) => (
  Rxjs.t<'a, 'b, 'd>,
  Rxjs.t<'a, 'b, 'e>,
  Rxjs.t<'a, 'b, 'f>,
  Rxjs.t<'a, 'b, 'g>,
)`  


### Dynamic.partition5
  
`let partition5: (
  Rxjs.t<'a, 'b, 'c>,
  (
    'c => option<'d>,
    'c => option<'e>,
    'c => option<'f>,
    'c => option<'g>,
    'c => option<'h>,
  ),
) => (
  Rxjs.t<'a, 'b, 'd>,
  Rxjs.t<'a, 'b, 'e>,
  Rxjs.t<'a, 'b, 'f>,
  Rxjs.t<'a, 'b, 'g>,
  Rxjs.t<'a, 'b, 'h>,
)`  


### Dynamic.partition6
  
`let partition6: (
  Rxjs.t<'a, 'b, 'c>,
  (
    'c => option<'d>,
    'c => option<'e>,
    'c => option<'f>,
    'c => option<'g>,
    'c => option<'h>,
    'c => option<'i>,
  ),
) => (
  Rxjs.t<'a, 'b, 'd>,
  Rxjs.t<'a, 'b, 'e>,
  Rxjs.t<'a, 'b, 'f>,
  Rxjs.t<'a, 'b, 'g>,
  Rxjs.t<'a, 'b, 'h>,
  Rxjs.t<'a, 'b, 'i>,
)`  


### Dynamic.partition7
  
`let partition7: (
  Rxjs.t<'a, 'b, 'c>,
  (
    'c => option<'d>,
    'c => option<'e>,
    'c => option<'f>,
    'c => option<'g>,
    'c => option<'h>,
    'c => option<'i>,
    'c => option<'j>,
  ),
) => (
  Rxjs.t<'a, 'b, 'd>,
  Rxjs.t<'a, 'b, 'e>,
  Rxjs.t<'a, 'b, 'f>,
  Rxjs.t<'a, 'b, 'g>,
  Rxjs.t<'a, 'b, 'h>,
  Rxjs.t<'a, 'b, 'i>,
  Rxjs.t<'a, 'b, 'j>,
)`  


### Dynamic.finalizeWithValue
  
`let finalizeWithValue: (
  Rxjs.t<'c, 's, 'o>,
  option<'o> => unit,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, 'o>`  


### Dynamic.delay
  
`let delay: Rxjs.t<'a, 'b, 'c> => Rxjs.t<'a, 'b, 'c>`  


### Dynamic.jitter
  
`let jitter: Rxjs.t<'a, 'b, 'c> => Rxjs.t<'a, 'b, 'c>`  


### Dynamic._log
  
`let _log: (
  ~enable: bool=?,
  Rxjs.t<'a, 'b, 'c>,
  'd,
) => Rxjs.t<'a, 'b, 'c>`  


### Dynamic.log
  
`let log: (
  ~enable: bool=?,
  Rxjs.t<'a, 'b, 'c>,
  'd,
) => Rxjs.t<'a, 'b, 'c>`  


### Dynamic.log_
  
`let log_: (~enable: bool=?, Rxjs.t<'a, 'b, 'c>, 'd) => unit`  


### Dynamic.mapLog
  
`let mapLog: (Rxjs.t<'a, 'b, 'c>, 'd, 'c => 'e) => Rxjs.t<'a, 'b, 'c>`  

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

unhandled kind moduleAlias
# FieldEmpty


Here as a touchpoint for copypaste  
  Explicitly typed as Field to force consistency with module type.  
  but you shouldnt need to do that if youre implementing your own.  



unhandled kind moduleAlias
unhandled kind moduleAlias
unhandled kind moduleAlias
unhandled kind moduleAlias
# FieldSum




### FieldSum.Sum1
  


### FieldSum.Sum2
  


### FieldSum.Sum3
  


### FieldSum.Sum4
  


### FieldSum.Sum5
  


### FieldSum.Sum6
  

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
  

unhandled kind moduleAlias
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

# Store




### Store.enum
  
`type enum = [#Busy | #Dirty | #Init | #Invalid | #Valid]`  


### Store.enumToPretty
  
`let enumToPretty: enum => string`  


### Store.enumToA
  
`let enumToA: enum => Prelude.String.t`  


### Store.t
  
`type t<'inner, 'output, 'error> =
  | Init('inner)
  | Dirty('inner)
  | Busy('inner)
  | Invalid('inner, 'error)
  | Valid('inner, 'output)`  


### Store.init
  
`let init: 'inner => t<'inner, 'output, 'error>`  


### Store.dirty
  
`let dirty: 'inner => t<'inner, 'output, 'error>`  


### Store.busy
  
`let busy: 'inner => t<'inner, 'output, 'error>`  


### Store.invalid
  
`let invalid: ('inner, 'error) => t<'inner, 'output, 'error>`  


### Store.valid
  
`let valid: ('inner, 'output) => t<'inner, 'output, 'error>`  


### Store.toEnum
  
`let toEnum: t<'i, 'o, 'e> => enum`  


### Store.inner
  
`let inner: t<'i, 'o, 'e> => 'i`  


### Store.mapInner
  
`let mapInner: (t<'i, 'o, 'e>, 'i => 'ib) => t<'ib, 'o, 'e>`  


### Store.bimap
  
`let bimap: (t<'i, 'o, 'e>, 'i => 'ib, 'o => 'ob) => t<'ib, 'ob, 'e>`  


### Store.output
  
`let output: t<'i, 'o, 'e> => option<'o>`  


### Store.mapOutput
  
`let mapOutput: (t<'a, 'b, 'c>, 'b => 'd) => t<'a, 'd, 'c>`  


### Store.error
  
`let error: t<'i, 'o, 'e> => option<'e>`  

# UseField




### UseField.Make
  
  
### UseField.Make.ret
  
`type ret = Form.t<F.t, F.actions<unit>>`  


### UseField.Make.use
  
`let use: (
  ~context: F.context,
  ~init: option<F.input>,
  ~validateInit: 'a,
) => ret`  

