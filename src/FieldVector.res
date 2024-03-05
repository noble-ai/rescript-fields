// Named Vector to avoid naming conflict with Tuple, but storage is tuples, AxM

// shadow global Dynamic with the impl chosen by FT
open! FieldTrip

type error = [#Whole(string) | #Part]
type resultValidate = Promise.t<Result.t<unit, string>>
type validateOut<'out> = 'out => resultValidate

module Context = {
  type t<'e, 'v, 'i> = {
    empty?: 'e,
    // When the product is valid, this validation is called allowing a check of all fields together
    validate?: 'v,
    inner: 'i,
  }

  let empty = (t) => t.empty
  let validate = (t) => t.validate
  let inner = (t) => t.inner

  let trimap = (e, f, g, c) => {
    {
      empty: ?c.empty->Option.map(e),
      validate: ?c.validate->Option.map(f),
      inner: c.inner->g,
    }
  }
}

module Change = {
  type t<'input, 'inner> = [#Set('input) | #Clear | #Inner('inner) | #Validate]
  let makeSet = input => #Set(input)

  let bimap = (f, g, c) => {
    switch c {
    | #Set(input) => #Set(f(input))
    | #Clear => #Clear
    | #Inner(inner) => #Inner(g(inner))
    | #Validate => #Validate
    }
  }

  let show = (c: t<string, string>) => {
    switch c {
    | #Set(input) => `Set(${input})`
    | #Clear => "Clear"
    | #Inner(inner) => `Inner(${inner})`
    | #Validate => "Validate"
    }
  }
}

module Actions = {
  type t<'input, 'inner, 'actionsInner> = {
    set: 'input => Change.t<'input, 'inner>,
    clear: () => Change.t<'input, 'inner>,
    inner: 'actionsInner,
    validate: () => Change.t<'input, 'inner>,
  }
}

// we want to apply a const function to a bunch of vector channels,
// Its short but kind of buzy, so keep one here
let const = (fn, a, _) => fn(a)

let outputresult = (toOutput, toEnum, a) => {
  switch a->toOutput {
  | Some(output) => Ok(output)
  | None => Error(a->toEnum)
  }
}

let resolveErr = (inner, e) => {
  switch e {
  | #Busy => Store.busy(inner)
  | #Invalid => Store.invalid(inner, #Part)
  | #Init => Store.init(inner)
  | #Dirty => Store.dirty(inner)
  | #Valid => Exn.raise("allResult must not fail when #Valid")
  }->Dynamic.return
}

// This module definition lets you  share the FieldProduct code
// but expose the structure given here
// while the FieldProduct stores
module type Interface = {
  // Call async validate when both children become valid
  let validateImmediate: bool
}

module type Tail = {
  type contextInner

  type input
  type inner
  type output
  type t
  let showInput: input => string
  let inner: t => inner
  let set: input => t
  let empty: contextInner => inner
  let hasEnum: (inner, FieldTrip.enum) => bool
  let toResultInner: inner => result<output, FieldTrip.enum>
  let validateInner: (contextInner, inner) => Dynamic.t<inner>

  type changeInner
  let showChangeInner: changeInner => string
  type actions
  let actions: actions
  let reduceChannel: (
    ~contextInner: contextInner,
    Dynamic.t<inner>,
    Indexed.t<unit>,
    changeInner,
  ) => Dynamic.t<inner>
  let reduceSet: (contextInner, Dynamic.t<inner>, Indexed.t<unit>, input) => Dynamic.t<inner>
  let toInputInner: inner => input
  let printErrorInner: inner => array<option<string>>
  let showInner: inner => array<string>
}

module Vector0 = {
  type input = ()
  type inner = ()
  type output = ()
  type error = error

  type t = Store.t<inner, output, error>

  type validate = validateOut<output>

  type contextInner = ()
  type context = ()

  let inputInner = () => ()
  let toInputInner = () => ()
  let input = (_store: t) => ()
  let showInput = () => ""

  let set = (): t => Store.valid((), ())

  let empty = (): inner => ()

  let initInner = () => ()
  let init = () => Store.valid((), ())

  let hasEnum = (_x, e) => e == #Valid

  let toResultInner = (): result<output, FieldTrip.enum> => Ok()
  let validateInner = (_context, inner: inner): Dynamic.t<inner> => empty()->Dynamic.return
  let validate = (_force, _context: context, store: t): Dynamic.t<t> => init()->Dynamic.return

  let inner = _ => ()
  let showInner = (_) => []

  let enum = (_) => #Valid
  let output = _ => ()
  let error = _ => None //Store.error
  let printErrorInner = (_inner: inner): array<option<string>> => []
  let printError = (_store: t): option<string> => None
  
  let show = (_store: t): string => `Vector0`

  type changeInner = ()
  let showChangeInner = (_ch: changeInner) => `()`

  type change = ()
  let showChange = (): string => ""

  type actions = ()
  let toChange = (_, _): change => ()
  let actions: actions = ()

  // We're counting on these streams producing values, so we cant just return the existing inner/store Dynamics - AxM
  let reduceChannel = (~contextInner, store, _change, _ch: changeInner): Dynamic.t<inner> => ()->Dynamic.return
  let reduceSet = (_contextInner, inner: Dynamic.t<inner>, _change: Indexed.t<unit>, _input): Dynamic.t<inner> => ()->Dynamic.return
  let reduce = (~context: context, store: Dynamic.t<t>, _change: Indexed.t<change>): Dynamic.t<t> => init()->Dynamic.return

}

module VectorRec = {
  module Make = (I: Interface, Head: Field, Tail: Tail) => {
    type input = (Head.input, Tail.input)
    type inner = (Head.t, Tail.inner)
    type output = (Head.output, Tail.output)
    type error = error

    type validate = validateOut<output>
    type contextInner = (Head.context, Tail.contextInner)
    type context = Context.t<input, validate, contextInner>

    type t = Store.t<inner, output, error>

    let showInput = (x: input) => {
      let (head, tail) = x
      let head = head->Head.showInput
      let tail = tail->Tail.showInput
      `${head}, ${tail}`
    }

    let set = (x: input): t => {
      let (head, tail) = x
      let head = head->Head.set
      let tail = tail->Tail.set->Tail.inner
      (head, tail)->Store.dirty
    }

    let empty = (context: contextInner): inner => {
      let (contextHead, contextTail) = context
      let head = contextHead->Head.init
      let tail = contextTail->Tail.empty
      (head, tail)
    }

    let init = context => context->empty->Store.init

    let validateOut = (~validate, ~immediate=false, inner: inner, out: output) => {
      switch validate {
      | Some(validate) if immediate =>
        out
        ->validate
        ->Dynamic.fromPromise
        ->Dynamic.map(
          Result.resolve(
            ~ok=_ => Store.valid(inner, out),
            ~err=e => Store.invalid(inner, #Whole(e)),
          ),
        )
        ->Dynamic.startWith(Store.busy(inner))
      // When we are given a validate function but not validateImmediate or force, do not assume valid until validated
      | Some(_validate) => Store.dirty(inner)->Dynamic.return
      | _ => Store.valid(inner, out)->Dynamic.return
      }
    }

    let hasEnum = (x, e) => {
      let (head, tail) = x
      let head = head->Head.enum == e
      let tail = tail->Tail.hasEnum(e)
      head || tail
    }

    let allResult = Tuple.Tuple2.uncurry(Result.all2)
    let toResultInner = (inner: inner): result<output, FieldTrip.enum> => {
      open Tuple.Tuple2
      (outputresult(Head.output, Head.enum, _), Tail.toResultInner)->napply(inner)->allResult
    }

    let makeStore = (~validate, inner: inner): Dynamic.t<t> => {
      // TODO: These predicated values are computed up front
      // so these promises are made, and then thrown away
      // Should predicate take a thunk for lazy evaluation? - AxM
      [
        // First Prioritize Busy first if any children are busy
        Result.predicate(inner->hasEnum(#Busy), Store.busy(inner)->Dynamic.return, #Invalid),
        // Then Prioritize Invalid state if any children are invalid
        Result.predicate(inner->hasEnum(#Invalid), Store.busy(inner)->Dynamic.return, #Invalid),
        // Otherwise take the first error we find
        inner->toResultInner->Result.map(validate(inner)),
      ]
      ->Array.reduce(Result.first, Error(#Invalid))
      // ->Tap.log("makeStore result"))
      ->Result.resolve(~ok=x => x, ~err=resolveErr(inner))
    }

    let validateInner = (context: contextInner, inner: inner): Dynamic.t<inner> => {
      let (head, tail) = inner
      let (contextHead, contextTail) = context
      let head = Head.validate(true, contextHead, head)
      let tail = Tail.validateInner(contextTail, tail)
      (head, tail)->Dynamic.combineLatest2
    }

    let validateImpl = (context: context, store: t): Dynamic.t<t> => {
      let validate = validateOut(~validate=context.validate, ~immediate=true)

      validateInner(context.inner, store->Store.inner)->Dynamic.bind(makeStore(~validate))
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      if !force && store->Store.toEnum == #Valid {
        store->Dynamic.return
      } else {
        validateImpl(context, store)
      }
    }

    type changeInner = Either.t<Head.change, Tail.changeInner>
    let showChangeInner = (ch: changeInner) =>
      switch ch {
      | Left(a) => `Head(${a->Head.showChange})`
      | Right(b) => `Tail(${b->Tail.showChangeInner})`
      }

    type change = Change.t<input, changeInner>
    let makeSet = input => #Set(input)

    let showChange = (change: change): string =>
      change->Change.bimap(showInput, showChangeInner, _)->Change.show

    type actions = (Head.change => change, Tail.actions)
    let actions: actions = ((c): change => #Inner(Left(c)), Tail.actions)

    let reduceField = (inner, change, reduce) => {
      // These individual field setters return a different type based on the field
      // So some functor trickery to share this code.. not going to bother now
      inner
      ->Dynamic.map(((head, _)) => head)
      ->reduce(change)
      ->Dynamic.withLatestFrom(inner)
      // Each A.reduce call may emit a series of states
      // but we can know that only the last one is valid?
      // store can also be producing new values via changes to other fields
      // which can go from valid to invalid or back
      // makeStore can also emit numerous values, but only when a is valid
      // So its only the last event here that causes numerous events.
      // so the type of product doesnt change the result
      // still, since this is now Dynamic and not promise,
      // these conditions could change,
      // but we dont know what the interaction between these things means yet
      // so use a concat "bind" to keep them separate
      ->Dynamic.map(((head, (_, tail))) => (head, tail))
    }

    let reduceChannel = (
      ~contextInner: contextInner,
      store,
      change: Indexed.t<unit>,
      ch: changeInner,
    ) => {
      let (contextA, contextB) = contextInner
      switch ch {
      | Left(ch) => reduceField(store, change->Indexed.const(ch), Head.reduce(~context=contextA))
      | Right(ch) => {
          let storehead = store->Dynamic.map(((head, _)) => head)
          let store = store->Dynamic.map(((_, tail)) => tail)
          Tail.reduceChannel(~contextInner=contextB, store, change, ch)
          ->Dynamic.withLatestFrom(storehead)
          ->Dynamic.map(((tail, head)) => (head, tail))
        }
      }
    }

    let reduceSet = (
      context: contextInner,
      inner: Dynamic.t<inner>,
      change: Indexed.t<unit>,
      input,
    ): Dynamic.t<inner> => {
      let (contextHead, contextTail) = context
      let (inputHead, inputTail) = input
      let changeHead = change->Indexed.map(_ => Head.makeSet(inputHead))
      let storeHead = inner->Dynamic.map(((head, _)) => head)
      let storeTail = inner->Dynamic.map(((_, tail)) => tail)

      let head = Head.reduce(~context=contextHead, storeHead, changeHead)
      let tail = Tail.reduceSet(contextTail, storeTail, change, inputTail)

      (head, tail)->Dynamic.combineLatest2
    }

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<
      t,
    > => {
      switch change.value {
      | #Set(input) => {
          let inner = store->Dynamic.map(Store.inner)
          reduceSet(context.inner, inner, change->Indexed.const(), input)->Dynamic.bind(
            makeStore(~validate=validateOut(~validate=context.validate, ~immediate=true)),
          )
        }
      | #Clear => context.inner->init->Dynamic.return
      | #Inner(ch) => {
          let validate: option<validate> = context.validate
          let validate = validateOut(~validate, ~immediate=I.validateImmediate)
          let storeInner = store->Dynamic.map(Store.inner)
          reduceChannel(
            ~contextInner=context.inner,
            storeInner,
            change->Indexed.const(),
            ch,
          )->Dynamic.bind(makeStore(~validate))
        }
      | #Validate =>
        store
        ->Dynamic.take(1)
        ->Dynamic.bind(store => {
          validate(false, context, store)
        })
      }
    }

    let toInputInner = (inner: inner) => (Head.input, Tail.toInputInner)->Tuple.Tuple2.napply(inner)
    let input = (store: t) =>
      (Head.input, Tail.toInputInner)->Tuple.Tuple2.napply(store->Store.inner)

    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printErrorInner = (inner: inner) => {
      let (head, tail) = (Head.printError, Tail.printErrorInner)->Tuple.Tuple2.napply(inner)
      Array.concat([head], tail)
    }

    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.map(error => {
        switch error {
        | #Whole(error) => error
        | #Part => store->Store.inner->printErrorInner->Array.catOptions->Array.joinWith(", ")
        }
      })
    }

    let showInner = (inner: inner) => {
      let (head, tail) = (Head.show, Tail.showInner)->Tuple.Tuple2.napply(inner)
      Array.concat([head], tail)
    }

    let show = (store: t): string => {
      `Vector3{
        validateImmediate: ${I.validateImmediate ? "true" : "false"},
        state: ${store->enum->enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${showInner(store->inner)->Array.joinWith(",\n")}
        }}`
    }
  }
}

module Vector1 = {
  module Make = (
    I: Interface,
    A: Field
  ) => VectorRec.Make( I, A, Vector0)
}

module Vector2 = {
  module Make = (
    I: Interface,
    A: Field, B: Field
  ) => VectorRec.Make( I, B, Vector1.Make(I, A))
}

module Vector3 = {
  module Make = (
    I: Interface,
    A: Field, B: Field, C: Field
  ) => VectorRec.Make( I, C, Vector2.Make(I, A, B))
}

module Vector4 = {
  module Make = (
    I: Interface,
    A: Field, B: Field, C: Field, D: Field
  ) => VectorRec.Make( I, D, Vector3.Make(I, A, B, C))
}

module Vector5 = {
  module Make = (
    I: Interface,
    A: Field, B: Field, C: Field, D: Field, E: Field
  ) => VectorRec.Make( I, E, Vector4.Make(I, A, B, C, D))
}

module Vector6 = {
  module Make = (
    I: Interface,
    A: Field, B: Field, C: Field, D: Field, E: Field, F: Field,
  ) => VectorRec.Make(I, F, Vector5.Make(I, A, B, C, D, E))
}

module Vector7 = {
  module Make = (
    I: Interface,
    A: Field, B: Field, C: Field, D: Field, E: Field, F: Field, G: Field,
  ) => VectorRec.Make(I, G, Vector6.Make(I, A, B, C, D, E, F))
}
