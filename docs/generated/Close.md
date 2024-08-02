# Close




### Close.t
  
`type t<'pack> = {pack: 'pack, close: unit => unit}`  


### Close.pack
  
`let pack: t<'pack> => 'pack`  


### Close.close
  
`let close: (t<'pack>, unit) => unit`  


### Close.map
  
`let map: (t<'a>, 'a => 'b) => t<'b>`  

