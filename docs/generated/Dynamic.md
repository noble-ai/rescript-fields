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

