# FieldArray




### FieldArray.Context
  
  
### FieldArray.Context.structure
  
`type structure<'output, 'element> = {
  validate?: array<'output> => Prelude.Promise.t<
    Prelude.Result.t<unit, string>,
  >,
  element: 'element,
}`  


### FieldArray.length
  
`let length: (
  ~len: int,
  Array.t<'a>,
) => Prelude.Promise.t<result<unit, string>>`  


### FieldArray.IArray
  
  
### FieldArray.IArray.filter
  
`let filter: array<F.t> => array<F.t>`  


### FieldArray.IArray.empty
  
`let empty: Context.structure<F.output, F.context> => array<F.t>`  


### FieldArray.IArray.validateImmediate
  
`let validateImmediate: bool`  


### FieldArray.filterIdentity
  
`let filterIdentity: array<'a> => array<'a>`  


### FieldArray.filterGrace
  
`let filterGrace: array<'t> => Array.t<'t>`  


### FieldArray.Make
  

