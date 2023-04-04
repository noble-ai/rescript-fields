external void: Js.Promise.t<'a> => unit = "%identity"

let map = (p, fn) => Js.Promise.then_(a => Js.Promise.resolve(fn(a)), p)
let const = (p, a) => p->map(_ => a)

let return = Js.Promise.resolve

let bind = (a, b) => Js.Promise.then_(b, a)
let join = (a: Js.Promise.t<Js.Promise.t<'a>>): Js.Promise.t<'a> => {
  a->bind(x => x)
}

// Call fn with the value from the promise, ignoring its return
let tap = (p: Js.Promise.t<'a>, fn: 'a => unit): Js.Promise.t<'a> => {
  p->bind(a => {
    fn(a)
    Js.Promise.resolve(a)
  })
}

// Call fn with the value from the promise, ignoring its return. but only continue when fn resolves
let tapBind = (p: Js.Promise.t<'a>, fn: 'a => Js.Promise.t<'b>): Js.Promise.t<'a> => {
  p->bind( a =>
    fn(a)->const( a)
  )
}

@val external all2: ((Js.Promise.t<'a>, Js.Promise.t<'b>)) => Js.Promise.t<('a, 'b)> = "Promise.all"
@val external all3: ((Js.Promise.t<'a>, Js.Promise.t<'b>, Js.Promise.t<'c>)) => Js.Promise.t<('a, 'b, 'c)> = "Promise.all"
@val external all4: ((Js.Promise.t<'a>, Js.Promise.t<'b>, Js.Promise.t<'c>, Js.Promise.t<'d>)) => Js.Promise.t<('a, 'b, 'c, 'd)> = "Promise.all"
@val external all5: ((Js.Promise.t<'a>, Js.Promise.t<'b>, Js.Promise.t<'c>, Js.Promise.t<'d>, Js.Promise.t<'e>)) => Js.Promise.t<('a, 'b, 'c, 'd, 'e)> = "Promise.all"

let catch = (a, b) => Js.Promise.catch(b, a)

@send external tapCatch: (Js.Promise.t<'a>, ('error) => unit) => Js.Promise.t<'a> = "catch"

@send external finally: (Js.Promise.t<'a>, () => unit) => Js.Promise.t<'a> = "finally"

let finallyVoid = (a, b) => {
  a
  ->tap(b)
  ->void
}

// Take an array of input, and a function that makes a promise producing b from one a.
// Start with a Promise that produces an empty array.
// Walk along the array of inputs, with the accumulator being a promise that produces the array of earlier inputs.
// bind off of that promise with a function that produces your Promise<b>, then map that Promise to append it on the existing array of bs - AxM
let sequence = (ins: array<'a>, fn: 'a => Js.Promise.t<'b>): Js.Promise.t<array<'b>> => {
  ins->Js.Array2.reduce(
    (p, a) => p->bind(bs => fn(a)->map(b => Js.Array.concat(bs, [b]))),
    Js.Promise.resolve([]),
  )
}

external errorToExn: Js.Promise.error => exn = "%identity"

external errorToJsObj: Js.Promise.error => Js.t<'a> = "%identity"


let toResult = (p: Js.Promise.t<'a>) => {
  p
  ->bind(a => Js.Promise.resolve(Ok(a)))
  ->catch(err => {
    let error = errorToJsObj(err)
    let message: string = error["message"]
    Js.Promise.resolve(Error(message))
  })
}

let sleep = time => {
  Js.Promise.make((~resolve, ~reject as _reject) => {
    Js.Global.setTimeout(() => resolve(. "ding"), time)->Void.void
  })
}
