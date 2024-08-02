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

