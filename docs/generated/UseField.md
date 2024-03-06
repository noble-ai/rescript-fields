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

