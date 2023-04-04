open Belt.Result

type t<'ok, 'error> = t<'ok, 'error>

let void = (_: t<'a, 'e>): unit => ()

let return = (a: 'a) => Ok(a)

let fromOption = (a: option<'a>, b: 'b): t<'a, 'b> => {
  switch a {
    | Some(a) => Ok(a)
    | None => Error(b)
  }
}

let toOption = (a: result<'ok, 'err>): option<'ok> => {
  switch a {
    | Ok(a) => Some(a)
    | _ => None
  }
}

let resolve = (a: result<'ok, 'err>, ~ok: 'ok => 'b, ~err: 'err => 'b): 'b => {
  switch a {
    | Ok(a) => ok(a)
    | Error(a) => err(a)
  }
}

let first = (a: result<'ok, 'err>, b: result<'ok, 'err>): result<'ok, 'err> => {
  switch (a, b) {
    | (Ok(a), _) => Ok(a)
    | (_, Ok(a)) => Ok(a)
    | (Error(a), _) => Error(a)
  }
}

let invert = (res: t<'a, 'b>): t<'b, 'a> => {
  switch res {
  | Ok(a) => Error(a)
  | Error(e) => Ok(e)
  }
}

// Keep the value v if true, otherwise return None
let predicate = (b: bool, v: 'v, e: 'err): t<'v, 'err> => {
  if b {
    Ok(v)
  } else {
    Error(e)
  }
}

let toOptionError = (a: result<'ok, 'err>): option<'err> => a->invert->toOption

let bind = Belt.Result.flatMap

let guard = (r: t<'ok, 'error>, fn: 'ok => bool, err: 'err) => {
  r->bind( (r) => {
    if fn(r) {
      Ok(r)
    } else {
      Error(err)
    }
  })
}

let const = (r: t<'ok, 'error>, c: 'const) => r->map( _ => c )

let tap = (result: t<'ok, 'error>, f: t<'ok, 'error> => unit): t<'ok, 'error> => {
  f(result)
  result
}

let map = (result: t<'ok, 'error>, fn: 'ok => 'ox): t<'ox, 'error> => {
  switch result {
  | Ok(e) => Ok(fn(e))
  | Error(a) => Error(a)
  }
}

let mapError = (result: t<'ok, 'error>, fn: 'error => 'ex): t<'ok, 'ex> => {
  switch result {
  | Error(e) => Error(fn(e))
  | Ok(a) => Ok(a)
  }
}

let bimap = (result: t<'ok, 'error>, ok: 'ok => 'ox, err: 'error => 'errorx): t<'ox, 'errorx> => {
  switch result {
  | Ok(e) => Ok(ok(e))
  | Error(a) => Error(err(a))
  }
}

let tapOk = (result: t<'ok, 'error>, fn: 'ok => unit): t<'ok, 'error> => {
  switch result {
  | Ok(a) => fn(a)
  | _ => ()
  }
  result
}

let tapError = (result: t<'ok, 'error>, fn: 'error => unit): t<'ok, 'error> => {
  switch result {
  | Error(e) => fn(e)
  | _ => ()
  }
  result
}

let merge = (
  ~consa: ('acc, 'a) => 'acc,
  ~conse: ('ecc, 'e) => 'ecc,
  ~eempty: 'ecc,
  acc: result<'acc, 'ecc>,
  r,
) =>
  switch (acc, r) {
  | (Ok(acc), Ok(a)) => Ok(consa(acc, a))
  | (Ok(_), Error(e)) => Error(conse(eempty, e))
  | (Error(acc), Error(e)) => Error(conse(acc, e))
  | (err, _) => err
  }

let apply = (f, v) => {
  switch v {
  | Error(e) => Error(e)
  | Ok(v) =>
    switch f {
    | Error(e) => Error(e)
    | Ok(f) => Ok(f(v))
    }
  }
}

// Cons A and B are the monoid operations for 'a and 'error
// Some errors are already arrays and will want to bind/flatmap etc. - AxM
let sequence = (
  ~aempty: 'acc,
  ~eempty: 'ecc,
  ~consa: ('acc, 'a) => 'acc,
  ~conse: ('ecc, 'e) => 'ecc,
  arr: array<t<'a, 'e>>,
): t<'acc, 'ecc> => {
  arr->Js.Array2.reduce(merge(~consa, ~conse, ~eempty), Ok(aempty))
}

let traverse = (
  ~aempty: 'acc,
  ~eempty: 'ecc,
  ~consa: ('acc, 'a) => 'acc,
  ~conse: ('ecc, 'e) => 'ecc,
  arr: array<'b>,
  f: 'b => t<'a, 'e>,
): t<'acc, 'ecc> => {
  arr->Js.Array2.map(f)->sequence(~eempty, ~consa, ~conse, ~aempty)
}

let all2 : (
  t<'a, 'err>,
  t<'b, 'err>,
) => t<('a, 'b), 'err> =
  (a,b) => {
    switch (a,b) {
      | (Ok(a), Ok(b)) => Ok((a,b))
      | (Error(err), _)
      | (_, Error(err)) => Error(err)
    }
  }

// Given three results with different OK types but the same error type,
// Return an Ok result with the tuple of all three if they are all Ok
// or return the first error
let all3 : (
  t<'a, 'err>,
  t<'b, 'err>,
  t<'c, 'err>
) => t<('a, 'b, 'c), 'err> =
  (a,b,c) => {
    switch (a,b,c) {
      | (Ok(a), Ok(b), Ok(c)) => Ok((a,b,c))
      | (Error(err), _, _)
      | (_, Error(err), _)
      | (_ , _, Error(err)) => Error(err)
    }
  }

let all4 : (
  t<'a, 'err>,
  t<'b, 'err>,
  t<'c, 'err>,
  t<'d, 'err>
) => t<('a, 'b, 'c, 'd), 'err> =
  (a,b,c, d) => {
    switch (a,b,c, d) {
      | (Ok(a), Ok(b), Ok(c), Ok(d)) => Ok((a,b,c,d))
      | (Error(err), _, _, _)
      | (_, Error(err), _, _)
      | (_ , _, Error(err), _)
      | (_ , _, _, Error(err))
       => Error(err)
    }
  }

let all5 : (
  t<'a, 'err>,
  t<'b, 'err>,
  t<'c, 'err>,
  t<'d, 'err>,
  t<'e, 'err>
) => t<('a, 'b, 'c, 'd, 'e), 'err> =
  (a,b,c, d, e) => {
    switch (a,b,c, d, e) {
      | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e)) => Ok((a,b,c,d, e))
      | (Error(err), _, _, _, _)
      | (_, Error(err), _, _, _)
      | (_ , _, Error(err), _, _)
      | (_ , _, _, Error(err), _)
      | (_ , _, _, _, Error(err))
       => Error(err)
    }
  }

let all6 : (
  t<'a, 'err>,
  t<'b, 'err>,
  t<'c, 'err>,
  t<'d, 'err>,
  t<'e, 'err>,
  t<'f, 'err>
) => t<('a, 'b, 'c, 'd, 'e, 'f), 'err> =
  (a,b,c, d, e, f) => {
    switch (a,b,c, d, e, f) {
      | (Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f)) => Ok((a,b,c,d, e, f))
      | (Error(err), _, _, _, _, _)
      | (_, Error(err), _, _, _, _)
      | (_ , _, Error(err), _, _, _)
      | (_ , _, _, Error(err), _, _)
      | (_ , _, _, _, Error(err), _)
      | (_ , _, _, _, _, Error(err))
       => Error(err)
    }
  }