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

