// Named Vector to avoid naming conflict with Tuple, but storage is tuples, AxM

// Copilot:
// Nested tuples refer to the concept of having tuples within tuples.
//  In the provided code excerpt, the Vector1 module is defined with a nested tuple structure.
// Vector1 is a module that contains another module called Make. The Make module takes a type parameter A of type Field.T. It then calls the VectorRec.Make function with two arguments: A and Vector0.
// Vector2 module also contains a Make module. This time, the Make module takes two type parameters: A and B, both of type Field.T. It then calls the VectorRec.Make function with two arguments: B and Vector1.Make(A).
// If we continue examining the code, we can see that this pattern continues with Vector3, Vector4, and so on. Each module Make takes additional type parameters and calls the VectorRec.Make function with the appropriate arguments.
// The nested tuples in this code structure allow for a flexible and extensible way to define vector modules with varying numbers of type parameters. Each module Make builds upon the previous one, creating a chain of nested tuples.
// Overall, nested tuples provide a way to organize and structure code by encapsulating related data within tuples, which can be further nested within other tuples or data structures.

type error = [#Whole(string) | #Part]
type resultValidate = Promise.t<Result.t<unit, string>>
type validateOut<'out> = 'out => resultValidate

module Context = {
  type t<'e, 'v, 'i> = {
    empty?: 'e,
    // When the product is valid, this validation is called allowing a check of all fields together
    validate?: 'v,
    inner: 'i,
    validateImmediate?: bool,
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

module Actions = {
  type t<'input, 'change, 'inner> = {
    set: 'input => 'change,
    clear: () => 'change,
    @ocaml.doc("Identity fields allow you to specify an empy value at the field and context level.
    In many places we have clearable inputs and want to allow this to reset the value.
    So instead of pattern matching on the change value, you can pass the optional value here as convenience.")
    opt: option<'input> => 'change,

    inner: 'inner,
    validate: () => 'change,
  }

  let trimap = (actions, fnInput, fn, fnInner) => {
    set: input => input->fnInput->actions.set->fn,
    clear: () => actions.clear()->fn,
    opt: x => x->Option.map(fnInput)->actions.opt->fn,
    inner: actions.inner->fnInner,
    validate: () => actions.validate()->fn
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

// This is a selection of Field.T with some "Inner" additions to allow recursion
// Did not include Field.T to avoid implementing things in FieldVector0 that noone needs - AxM
module type Tail = {
  type contextInner
  type context

  type input
  type t
  type inner
  type output
  let showInput: input => string
  let inner: t => inner
  let set: input => t
  let emptyInner: contextInner => inner
  let empty: context => inner
  let hasEnum: (inner, Store.enum) => bool
  let toResultInner: inner => result<output, Store.enum>
  let validateInner: (contextInner, inner) => Rxjs.t<Rxjs.foreign, Rxjs.void, inner>

  type actionsInner<'change>
  let mapActionsInner: (actionsInner<'change>, ('change => 'b)) => actionsInner<'b>

  @ocaml.doc("partition is opaque here but will be a composition of Form.t") // TODO: Why?
  // TODO: type can be specified here? - AxM
  type partition
  let splitInner: (inner, actionsInner<()>) => partition

  let makeDynInner: (contextInner, option<input>, Rxjs.Observable.t<input>) => 
    Dyn.t<Close.t<Form.t<inner, actionsInner<()>>>>

  let toInputInner: inner => input
  let printErrorInner: inner => array<option<string>>
  let showInner: inner => array<string>
}

// Vector0 is only a degenerate base case so its not useful to create one as a fully fledged Field.
// We use makeDynInner to terminate a chain of VectorRec makeDynInner to create a vector of the desired length 
// But the behavior of makeDyn "undefined" and can be trivially simple to satisfy the contract of Field.
// Other functions are implemented to return dynamic values that emit in line with the VectorRec so 
// We can use combineLatest there and not get hung up waiting for this field to return
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

  let emptyInner: contextInner => inner = () => ()
  let empty = emptyInner

  let initInner = () => ()
  let init = () => Store.valid((), ())

  let hasEnum = (_x, e) => e == #Valid

  let toResultInner = (): result<output, Store.enum> => Ok()
  let validateInner = (_context, _inner: inner): Rxjs.t<Rxjs.foreign, Rxjs.void,inner> => emptyInner()->Dynamic.return
  let validate = (_force, _context: context, _store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => init()->Dynamic.return

  let inner = _ => ()
  let showInner = (_) => []

  // Advertise as Valid always so we do not hinder parents that are waiting for all their children to be valid
  let enum = (_) => #Valid
  let output = _ => ()
  let error = _ => None //Store.error
  let printErrorInner = (_inner: inner): array<option<string>> => []
  let printError = (_store: t): option<string> => None
  
  let show = (_store: t): string => `Vector0`

  type actionsInner<'change> = ()
  let mapActionsInner = (_actionsInner, _fn) => ()

  // Both our root actions and inner actions produce "change"
  type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
  let mapActions = (actions, fn) => actions->Actions.trimap(x=>x, mapActionsInner(fn), fn)

  type partition = ()
  let splitInner = (_, _) => ()

  // We have no meaningful actions here, but you may get an external set event from a larger vector
  // So we want to produce a value for each set that comes in, at least
  let makeDynInner = (_context: contextInner, _initial: option<input>, set: Rxjs.Observable.t<input>)
    : Dyn.t<Close.t<Form.t<inner, actionsInner<()>>>>
  => {
    let pack: Form.t<'f, 'a> = { field: (), actions: () }
    let close = () => ()
    let first: Close.t<'fa> = {pack, close} 
    let dyn = 
          set
          ->Dynamic.map( (_): Close.t<Form.t<'f, 'a>> => first)
          ->Dynamic.map(Dynamic.return)

    {first, dyn}
  }

  // I dont think you're going to find much use in creating a Vector0 directly but I may be wrong. 
  let makeDyn = (_context: context, _initial: option<input>, _set: Rxjs.Observable.t<input>, _val: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
    => {
    let actions: actions<()> = {
      set: ignore,
      clear: ignore, 
      opt: ignore,
      validate: ignore,
      inner: (),
    }

    let dyn = Rxjs.Subject.makeEmpty()->Rxjs.toObservable
    { first: {close: ignore, pack: {field: Store.init(), actions}}, dyn}
  }
}

module VectorRec = {
  module Make = (Head: Field.T, Tail: Tail) => {
    type input = (Head.input, Tail.input)
    type inner = (Head.t, Tail.inner)
    type output = (Head.output, Tail.output)
    type error = error

    type validate = validateOut<output>
    type contextInner = (Head.context, Tail.contextInner)
    type context = Context.t<input, validate, contextInner>

    type t = Store.t<inner, output, error>

    let showInput = (input: input) => {
      let (head, tail) = Tuple.bimap(Head.showInput, Tail.showInput, input)
      `${head}, ${tail}`
    }

    let set = (x: input): t => 
      Tuple.bimap(Head.set, x => x->Tail.set->Tail.inner, x)
      ->Store.dirty

    let emptyInner = (context: contextInner): inner => 
      Tuple.bimap(Head.init, Tail.emptyInner, context)
    let empty = (c: context) => c.inner->emptyInner

    let init = (context: context) => context.inner->emptyInner->Store.init

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
    let toResultInner = (inner: inner): result<output, Store.enum> => {
      open Tuple.Tuple2
      (outputresult(Head.output, Head.enum, _), Tail.toResultInner)
      ->napply(inner)
      ->allResult
   }

    let makeStore = (~validate, inner: inner): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
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
      ->Result.resolve(~ok=x => x, ~err=resolveErr(inner))
    }

    let validateInner = (context: contextInner, inner: inner): Rxjs.t<Rxjs.foreign, Rxjs.void,inner> => {
      let (head, tail) = inner
      let (contextHead, contextTail) = context
      let head = Head.validate(true, contextHead, head)
      let tail = Tail.validateInner(contextTail, tail)
      (head, tail)->Dynamic.combineLatest2
    }

    let validateImpl = (context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      let validate = validateOut(~validate=context.validate, ~immediate=true)

      validateInner(context.inner, store->Store.inner)->Dynamic.bind(makeStore(~validate))
    }

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      if !force && store->Store.toEnum == #Valid {
        store->Dynamic.return
      } else {
        validateImpl(context, store)
      }
    }

    type actionsInner<'change> = (Head.actions<'change>, Tail.actionsInner<'change>)
    let mapActionsInner = ((head, tail), fn) => (head->Head.mapActions(fn), tail->Tail.mapActionsInner(fn))

    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions, fn) => actions->Actions.trimap(x => x, fn, mapActionsInner(_, fn))
    
    type partition = (Form.t<Head.t, Head.actions<()>>, Tail.partition)
    let splitInner = (inner: inner, actions: actionsInner<()>): partition => {
      let (field, it) = inner 
      let (ah, at) = actions
      ( {field: field, actions: ah}, Tail.splitInner(it, at))
    }

    let split = (part: Form.t<t, actions<()>>): partition => {
      splitInner( part.field->Store.inner, part.actions.inner)
    }

    let logField = Dynamic.map(_, Dynamic.tap(_, (x: Close.t<Form.t<'t, 'a>>) => {
      Console.log2("FieldVectorRec field", x.pack.field)
    }))

  let makeDynInner = (context: contextInner, initial: option<input>, set: Rxjs.Observable.t<input>)
    : Dyn.t<Close.t<Form.t<inner, actionsInner<()>>>>
    => {
    let setHead = set->Dynamic.map(Tuple.Nested.head)
    let setTail = set->Dynamic.map(Tuple.Nested.rest)
    let (contextHead, contextTail) = context 

    let (initialHead, initialTail) =  initial->Option.distribute2

    let {first: firstHead, dyn: firstDyn} = Head.makeDyn(contextHead, initialHead, setHead, None)
    let {first: firstTail, dyn: tailDyn} = Tail.makeDynInner(contextTail, initialTail, setTail)

    let first: Close.t<Form.t<'f, 'a>> = {
      pack: {
        field: (firstHead.pack.field, firstTail.pack.field),
        actions: (firstHead.pack.actions, firstTail.pack.actions)
        },
      close: () => {firstHead.close(); firstTail.close()}
    }


    let dyn = 
    Dynamic.combineLatest2((firstDyn, tailDyn))
    ->Dynamic.map( ((head, tail)) => {
      Dynamic.combineLatest2((head, tail))
      ->Dynamic.map( ((head, tail)): Close.t<Form.t<'f, 'a>> => {
        pack: {
          field: (head.pack.field, tail.pack.field),
          actions: (head.pack.actions, tail.pack.actions)
        },
        close: () => {head.close(); tail.close()}
      })
    })

    {first, dyn}
  }

  let makeDyn = (context: context, initial: option<input>, setOuter: Rxjs.Observable.t<input>, valOuter: option<Rxjs.Observable.t<()>>)
    : Dyn.t<Close.t<Form.t<t, actions<()>>>>
    => {
    let field = 
      initial
      ->Option.map(set)
      ->Option.or(init(context))
    
    let complete = Rxjs.Subject.makeEmpty()
    let clear = Rxjs.Subject.makeEmpty()
    let opt = Rxjs.Subject.makeEmpty()
    let valInner = Rxjs.Subject.makeEmpty()
    let val = valOuter->Option.map(Rxjs.merge2(_, valInner))->Option.or(valInner->Rxjs.toObservable)

    let setInner: Rxjs.t<'csi, 'ssi, input> = Rxjs.Subject.makeEmpty()
    let set = Rxjs.merge2(setOuter, setInner)

    let fnValidate = validateOut(~validate=context.validate, ~immediate=context.validateImmediate->Option.or(true))

    let {first: firstInner, dyn: dynInner} = makeDynInner(context.inner, initial, set)

    let actionsFirst: actions<()> = {
      set: Rxjs.next(setInner),
      clear: Rxjs.next(clear),
      // reset: Rxjs.next(reset),
      opt: Rxjs.next(opt),
      validate: Rxjs.next(valInner),
      inner: firstInner.pack.actions, 
    } 

    let close = Rxjs.next(complete)

    let first: Close.t<Form.t<'f, 'a>> = {pack: { field, actions: actionsFirst }, close}

    let dyn = 
      dynInner
      ->Dynamic.map(Dynamic.switchMap(_, (inner: Close.t<Form.t<'fa, 'ai>>) => 
      makeStore(~validate=fnValidate, inner.pack.field)
      ->Dynamic.map( (field): Close.t<Form.t<'f, actions<()>>> => {
        pack: {
          field,
          actions: {
            ...actionsFirst,
            inner: inner.pack.actions,
          }
        },
        close
      })
    ))
    ->Rxjs.pipe(Rxjs.shareReplay(1))
    ->Rxjs.pipe(Rxjs.takeUntil(complete))

    {first, dyn}
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
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${showInner(store->inner)->Array.joinWith(",\n")}
        }}`
    }
  }
}

module Vector1 = {
  module Make = (A: Field.T) => VectorRec.Make(A, Vector0)
}

module Vector2 = {
  module Make = (
    A: Field.T, B: Field.T
  ) => VectorRec.Make(B, Vector1.Make(A))
}

module Vector3 = {
  module Make = (
    A: Field.T, B: Field.T, C: Field.T
  ) => VectorRec.Make( C, Vector2.Make(A, B))
}

module Vector4 = {
  module Make = (
    A: Field.T, B: Field.T, C: Field.T, D: Field.T
  ) => VectorRec.Make( D, Vector3.Make(A, B, C))
}

module Vector5 = {
  module Make = (
    A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T
  ) => VectorRec.Make( E, Vector4.Make(A, B, C, D))
}

module Vector6 = {
  module Make = (
    A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T,
  ) => VectorRec.Make(F, Vector5.Make(A, B, C, D, E))
}

module Vector7 = {
  module Make = (
    A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T, G: Field.T,
  ) => VectorRec.Make(G, Vector6.Make(A, B, C, D, E, F))
}
