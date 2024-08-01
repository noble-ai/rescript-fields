// collecting actions available for operating on validation processes
// type t<'a> = Rxjs.t<Rxjs.foreign, Rxjs.void, 'a>

let return = Rxjs.return
let fromPromise = Rxjs.fromPromise
let toPromise = Rxjs.lastValueFrom
let toHistory = (x: Rxjs.t<'c, 's, 'out>) =>
  x
  ->Rxjs.pipe(Rxjs.scan((acc, v, _) => Array.concat(acc, [v]), []))
  ->Rxjs.pipe(Rxjs.startWith([]))
  ->Rxjs.lastValueFrom

let startWith = (t, a) => t->Rxjs.pipe(Rxjs.startWith(a))

let combineLatest = Rxjs.combineLatestArray
let combineLatest2 = ((a, b)) => Rxjs.combineLatest2(a, b)
let combineLatest3 = ((a, b, c)) => Rxjs.combineLatest3(a, b, c)
let combineLatest4 = ((a, b, c, d)) => Rxjs.combineLatest4(a, b, c, d)
let combineLatest5 = ((a, b, c, d, e)) => Rxjs.combineLatest5(a, b, c, d, e)
let combineLatest6 = ((a, b, c, d, e, f)) => Rxjs.combineLatest6(a, b, c, d, e, f)

let map = (a, fn) => a->Rxjs.pipe(Rxjs.map((x, _index) => fn(x)))
let mapi = (a, fn) => a->Rxjs.pipe(Rxjs.map((x, index) => fn(x, index)))

let const = (a, v) => a->Rxjs.pipe(Rxjs.map((_x, _index) => v))

let bind = (a: Rxjs.t<'ca, 'sa, 'out>, fn: 'a => Rxjs.t<Rxjs.foreign, Rxjs.void, 'b>): Rxjs.t<'ca, 'sa, 'b> => a->Rxjs.pipe(Rxjs.concatMap(fn))
let merge = (a: Rxjs.t<'ca, 'sa, 'a>, fn: 'a => Rxjs.t<Rxjs.foreign, Rxjs.void, 'b>): Rxjs.t<'ca, 'sa, 'b> => a->Rxjs.pipe(Rxjs.mergeMap(fn))
let switchMap = (a: Rxjs.t<'ca, 'sa, 'a>, fn: 'a => Rxjs.t<Rxjs.foreign, Rxjs.void, 'b>): Rxjs.t<'ca, 'sa, 'b> => a->Rxjs.pipe(Rxjs.switchMap(fn))
let switchSequence = Rxjs.pipe(_, Rxjs.switchMap(x => x))

let tap = (a, fn) => a->Rxjs.pipe(Rxjs.tap(fn))
let tap_ = (a, fn) => tap(a, fn)->ignore
let filter = (a, fn) => a->Rxjs.pipe(Rxjs.filter(fn))
let finalize = (a, fn) => a->Rxjs.pipe(Rxjs.finalize(fn))
let finally = (x, fn) => {
  x->Rxjs.lastValueFrom->Promise.tap(fn)->Promise.void
}

let withLatestFrom = (a, s) => a->Rxjs.pipe(Rxjs.withLatestFrom(s))
let withLatestFrom2 = (obs, a, b) => obs->Rxjs.pipe(Rxjs.withLatestFrom2(a, b))

let take = (a, n) => a->Rxjs.pipe(Rxjs.take(n))

let keepMap = (a, fn) => a->Rxjs.pipe(Rxjs.keepMap(fn))

let contramap = (a: Rxjs.Observer.t<'a>, fn: 'b => 'a): Rxjs.Observer.t<'b> => {
  next: (. x) => { a.next(. fn(x)) },
  error: (. err) => { a.error(. err) },
  complete: (. ) => { a.complete(. ) }
}

let contrafilter = (a: Rxjs.Observer.t<'a>, fn: 'b => option<'a>): Rxjs.Observer.t<'b> => {
  next: (. x) => {
    switch (fn(x)) {
    | Some(v) => a.next(. v)
    | None => ()
    }
  },
  error: a.error,
  complete: a.complete
}

let contraCatOptions = (a: Rxjs.Observer.t<'a>): Rxjs.Observer.t<option<'a>> =>
  contrafilter(a, x => x)


let partition2 = (a, (fna, fnb)) => (
  a->keepMap(fna),
  a->keepMap(fnb)
)
let partition3 = (a, (fna, fnb, fnc)) => (
  a->keepMap(fna),
  a->keepMap(fnb),
  a->keepMap(fnc),
)
let partition4 = (a, (fna, fnb, fnc, fnd)) => (
  a->keepMap(fna),
  a->keepMap(fnb),
  a->keepMap(fnc),
  a->keepMap(fnd),
)
let partition5 = (a, (fna, fnb, fnc, fnd, fne)) => (
  a->keepMap(fna),
  a->keepMap(fnb),
  a->keepMap(fnc),
  a->keepMap(fnd),
  a->keepMap(fne),
)
let partition6 = (a, (fna, fnb, fnc, fnd, fne, fnf)) => (
  a->keepMap(fna),
  a->keepMap(fnb),
  a->keepMap(fnc),
  a->keepMap(fnd),
  a->keepMap(fne),
  a->keepMap(fnf),
)

let partition7 = (a, (fna, fnb, fnc, fnd, fne, fnf, fng)) => (
  a->keepMap(fna),
  a->keepMap(fnb),
  a->keepMap(fnc),
  a->keepMap(fnd),
  a->keepMap(fne),
  a->keepMap(fnf),
  a->keepMap(fng),
)

// https://stackoverflow.com/questions/67213477/rxjs-finalize-pass-the-last-emitted-value-to-the-callback
let finalizeWithValue = (source: Rxjs.t<'c, 's, 'o>, callback: option<'o> => unit) => {
  Rxjs.defer(() => {
    let lastValue = ref(None)
    source
    ->tap(value => lastValue.contents = Some(value))
    ->finalize(() => callback(lastValue.contents))
  })
}

let delay = Rxjs.pipe(
  _,
  Rxjs.delayWhen(_ => Rxjs.interval(Int.random(2, 40))->take(1)->const()),
)

// create random delay for each value, but keep the order
let jitter = bind(_, x => x->return->delay)

let _log = (~enable=true,d, s) => d->tap(_x => { if enable { Console.log(s) } })
let log = (~enable=true, d, s) => d->tap(x => { if enable { Console.log2(s, x) } })
let log_ = (~enable=true, d, s) => {log(~enable, d, s)->ignore}

let mapLog = (d, s, fn) => d->tap(x => Console.log2(s, fn(x)))