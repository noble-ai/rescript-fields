open Rxjs
type t<'a> = t<foreign, void, 'a>
let return = return
let fromPromise = fromPromise
let toPromise = lastValueFrom

let startWith = (t, a) => t->pipe(startWith(a))

let combineLatest = combineLatestArray
let combineLatest2 = ((a, b)) => combineLatest2(a,b)
let combineLatest3 = ((a,b,c)) => combineLatest3(a,b,c)
let combineLatest4 = ((a,b,c,d)) => combineLatest4(a,b,c,d)
let combineLatest5 = ((a,b,c,d,e)) => combineLatest5(a,b,c,d,e)
let combineLatest6 = ((a,b,c,d,e,f)) => combineLatest6(a,b,c,d,e,f)

let map = (a, fn) => a->pipe(map(. (x, _index) => fn(x)))
let bind = (a: t<'a>, fn: 'a => t<'b>): t<'b> => a->pipe(concatMap(fn))
let merge = (a: t<'a>, fn: 'a => t<'b>): t<'b> => a->pipe(mergeMap(fn))
let tap = (a, fn) => a->pipe(Rxjs.tap(fn))

let finally = (x, fn) => {
  x
  ->lastValueFrom
  ->Promise.tap(fn)
  ->Promise.void
}

let withLatestFrom = (a, s) => a->pipe( withLatestFrom(s) )
let withLatestFrom2 = (obs, a, b) => obs->pipe( withLatestFrom2(a, b) )

let take = (a, n) => a->pipe( Rxjs.take(n))
  