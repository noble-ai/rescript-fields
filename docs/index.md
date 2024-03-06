invalid kind
invalid kind
# FieldString




### FieldString.error
  
`type error = [
  | #Empty
  | #External(string)
  | #TooLong
  | #TooShort
]`  


### FieldString.validate
  
`type validate = string => Prelude.Promise.t<
  Prelude.Result.t<string, error>,
>`  


### FieldString.context
  
`type context = {validate?: validate}`  


### FieldString.length
  
`let length: (~min: int=?, ~max: int=?, unit) => validate`  


### FieldString.min
  
`let min: 'a => option<(option<'a>, option<'b>)>`  


### FieldString.max
  
`let max: 'a => option<(option<'b>, option<'a>)>`  


### FieldString.minmax
  
`let minmax: ('a, 'b) => option<(option<'a>, option<'b>)>`  


### FieldString.input
  
`type input = string`  


### FieldString.output
  
`type output = string`  


### FieldString.inner
  
`type inner = string`  


### FieldString.t
  
`type t = Store.t<inner, output, error>`  


### FieldString.IString
  
  
### FieldString.IString.validateImmediate
  
`let validateImmediate: bool`  


### FieldString.change
  
`type change<'set> = [
  | #Clear
  | #Reset
  | #Set('set)
  | #Validate
]`  


### FieldString.actions
  
`type actions<'set> = {
  clear: unit => change<'set>,
  reset: unit => change<'set>,
  validate: unit => change<'set>,
  set: 'set => change<'set>,
}`  


### FieldString.Make
  
  
### FieldString.Make.error
  
`type error = error`  


### FieldString.Make.validate
  
`type validate = validate`  


### FieldString.Make.context
  
`type context = context`  


### FieldString.Make.input
  
`type input = input`  


### FieldString.Make.output
  
`type output = output`  


### FieldString.Make.inner
  
`type inner = inner`  


### FieldString.Make.t
  
`type t = t`  


### FieldString.Make.showInput
  
`let showInput: input => string`  


### FieldString.Make.empty
  
`let empty: 'a => string`  


### FieldString.Make.init
  
`let init: 'a => Store.t<string, 'b, 'c>`  


### FieldString.Make.set
  
`let set: 'a => Store.t<'a, 'b, 'c>`  


### FieldString.Make.validate
  
`let validate: (bool, context, t) => Dynamic.t<t>`  


### FieldString.Make.change
  
`type change = change<input>`  


### FieldString.Make.makeSet
  
`let makeSet: 'a => [> #Set('a)]`  


### FieldString.Make.showChange
  
`let showChange: change => string`  


### FieldString.Make.actions
  
`type actions = actions<input>`  


### FieldString.Make.actions
  
`let actions: actions<'a>`  


### FieldString.Make.reduce
  
`let reduce: (
  ~context: context,
  Dynamic.t<t>,
  Indexed.t<change>,
) => Dynamic.t<t>`  


### FieldString.Make.enum
  
`let enum: Store.t<'a, 'b, 'c> => Store.enum`  


### FieldString.Make.inner
  
`let inner: Store.t<'a, 'b, 'c> => 'a`  


### FieldString.Make.input
  
`let input: Store.t<'a, 'b, 'c> => 'a`  


### FieldString.Make.output
  
`let output: Store.t<'a, 'b, 'c> => option<'b>`  


### FieldString.Make.error
  
`let error: Store.t<'a, 'b, 'c> => option<'c>`  


### FieldString.Make.show
  
`let show: t => string`  


### FieldString.Make.printError
  
`let printError: t => option<string>`  


### FieldString.contextNonEmpty
  
`let contextNonEmpty: context`  

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
  

invalid kind
# Indexed




### Indexed.t
  
`type t<'a> = {value: 'a, index: int, priority: int}`  


### Indexed.value
  
`let value: t<'a> => 'a`  


### Indexed.index
  
`let index: t<'a> => int`  


### Indexed.priority
  
`let priority: t<'a> => int`  


### Indexed.map
  
`let map: (t<'a>, 'a => 'b) => t<'b>`  


### Indexed.const
  
`let const: (t<'a>, 'v) => t<'v>`  


### Indexed.latest
  
`let latest: (int, t<'b>) => int`  


### Indexed.highest
  
`let highest: (int, t<'b>) => int`  


### Indexed.overValue
  
`let overValue: (t<'a>, 'a => option<'b>) => option<t<'b>>`  


### Indexed.overValue2
  
`let overValue2: ('a => option<'b>, t<'a>) => option<t<'b>>`  

# Priorities




### Priorities.t
  
`type t<'v> = Prelude.Map.t<int, 'v>`  


### Priorities.empty
  
`let empty: unit => Prelude.Map.t<'a, 'b>`  


### Priorities.apply
  
`let apply: (Prelude.Map.t<'a, 'b>, 'a, 'b) => Prelude.Map.t<'a, 'b>`  


### Priorities.get
  
`let get: (t<int>, int) => option<int>`  

# Store




### Store.enum
  
`type enum = [#Busy | #Dirty | #Init | #Invalid | #Valid]`  


### Store.enumToPretty
  
`let enumToPretty: enum => string`  


### Store.enumToA
  
`let enumToA: enum => Js.String2.t`  


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




### UseField.change
  
`type change<'change, 'update, 'complete> = {
  change: 'change,
  onUpdate?: 'update,
  onComplete?: 'complete,
}`  


### UseField.applyLatest
  
`let applyLatest: (
  ~setfield: ('a => 'b) => unit,
  ~subject: Rxjs.t<'c, Rxjs.source<'b>, 'd>,
  Rxjs.t<'e, 'f, 'b>,
) => Rxjs.t<'e, 'f, 'b>`  


### UseField.applyUpdate
  
`let applyUpdate: (
  ~onUpdate: 'a => 'b=?,
  Rxjs.t<'c, 'd, 'a>,
) => Rxjs.t<'c, 'd, 'a>`  


### UseField.applyComplete
  
`let applyComplete: (
  ~onComplete: 'a => 'b=?,
  Rxjs.t<'c, 'd, 'a>,
) => Rxjs.t<'c, 'd, 'a>`  


### UseField.applyOut
  
`let applyOut: (
  ~value: 'a,
  ~index: int,
  ~out: Rxjs.t<'c, Rxjs.source<(int, 'a)>, 'o>,
  Rxjs.t<'b, 'd, 'e>,
) => Rxjs.t<'b, 'd, 'e>`  


### UseField.applyChange
  
`let applyChange: (
  ~reduce: (
    Rxjs.t<Rxjs.foreign, Rxjs.void, 'a>,
    Indexed.t<'ch>,
  ) => Rxjs.t<Rxjs.foreign, Rxjs.void, 'b>,
  ~subject: Rxjs.t<'c, Rxjs.source<'b>, 'a>,
  ~setfield: ('d => 'b) => unit,
  ~changeOut: Rxjs.t<
    'e,
    Rxjs.source<
      (int, change<'ch, 'b => 'f, option<'b> => 'g>),
    >,
    'h,
  >,
  ~show: 'i,
  int,
  change<'ch, 'b => 'f, option<'b> => 'g>,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, 'b>`  


### UseField.applyValidate
  
`let applyValidate: (
  ~validate: (bool, 'a, 'b) => Rxjs.t<
    Rxjs.foreign,
    Rxjs.void,
    'c,
  >,
  ~subject: Rxjs.t<'d, Rxjs.source<'c>, 'b>,
  ~context: 'a,
  ~setfield: ('e => 'c) => unit,
  ('c => 'f, 'c => 'g),
) => Rxjs.t<Rxjs.foreign, Rxjs.void, 'c>`  


### UseField.applyFlush
  
`let applyFlush: (
  ~subject: Rxjs.t<'a, 'b, 'c>,
  'c => 'd,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, 'c>`  


### UseField.keyByIndex
  
`let keyByIndex: Rxjs.t<'a, 'b, 'c> => Rxjs.t<'a, 'b, (int, 'c)>`  


### UseField.scanActive
  
`let scanActive: (
  Rxjs.t<'ca, 'sa, (int, 'a)>,
  Rxjs.t<'cr, 'sr, (int, 'a)>,
) => Rxjs.t<Rxjs.foreign, Rxjs.void, Prelude.Map.t<int, 'a>>`  


### UseField.traverseIndexed
  
`let traverseIndexed: ('a => option<'b>, (int, 'a)) => option<(int, 'b)>`  


### UseField.Make
  
  
### UseField.Make.input
  
`type input = F.input`  


### UseField.Make.output
  
`type output = F.output`  


### UseField.Make.context
  
`type context = F.context`  


### UseField.Make.reduce
  
`type reduce = (
  ~onUpdate: F.t => unit=?,
  ~onComplete: option<F.t> => unit=?,
  F.change,
) => unit`  


### UseField.Make.return
  
`type return = {
  field: F.t,
  input: F.input,
  output: option<F.output>,
  reduce: reduce,
  reducePromise: F.change => Prelude.Promise.t<option<F.t>>,
  validate: (
    ~onChange: F.t => unit,
    ~onComplete: F.t => unit,
  ) => unit,
  validatePromise: unit => Prelude.Promise.t<F.t>,
  flush: unit => Prelude.Promise.t<F.t>,
  handleSubmit: (
    F.output => Prelude.Promise.t<unit>,
    ReactEvent.Form.t,
  ) => unit,
  handleOutput: (
    F.output => Prelude.Promise.t<unit>,
  ) => unit,
}`  


### UseField.Make.change
  
`type change = change<
  F.change,
  F.t => unit,
  option<F.t> => unit,
>`  


### UseField.Make.validate
  
`type validate = (F.t => unit, F.t => unit)`  


### UseField.Make.sync
  
`type sync = [#Flush(F.t => unit) | #Validate(validate)]`  


### UseField.Make.submit
  
`type submit = F.output => Prelude.Promise.t<unit>`  


### UseField.Make.operation
  
`type operation = [#Change(change) | #Sync(sync)]`  


### UseField.Make.toChange
  
`let toChange: [> #Change('a)] => option<'a>`  


### UseField.Make.onCompleteOutput
  
`let onCompleteOutput: (submit, F.t) => unit`  


### UseField.Make.use
  
`let use: (
  ~context: context,
  ~init: F.input=?,
  ~validateInit: bool=?,
  unit,
) => return`  

