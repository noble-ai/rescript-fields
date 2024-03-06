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

