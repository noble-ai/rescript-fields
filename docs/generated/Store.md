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

