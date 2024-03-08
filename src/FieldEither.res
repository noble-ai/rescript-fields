// prefer shadowing Dynamic

@@ocaml.doc("Field Either is the generic implentation for FieldSum
Instead of customizing the sum type, it is encoded as a nested Either
This leaves  the confusion around that translation apart from the
reduce and validation logic which is hard enough to understand on its own
FieldEither is implemented constructively from Either2(A: Field, B: Field)
and Rec(Head: Field, Tail: Tail)
")

module type Interface = {
  let validateImmediate: bool
}

type error = [#Whole(string) | #Part]

module Actions = FieldVector.Actions

// the Tail module type is an extension of Field with some extras for
// managing the recursive construction of FieldEither3,4,5...
// Some elements of Field are baked in to include a non recursive
// decoration so those need to be stripped back to structures that
// can be split and recursed.

module type Tail = {
  include Field.T
  type contextInner

  let initInner: contextInner => inner
  let showInput: input => string
  let setInner: input => inner

  let outputInner: inner => option<output>
  let validateInner: (bool, contextInner, inner) => Dynamic.t<inner>

  type changeInner
  let showChangeInner: changeInner => string

  // actionsInner is a collection of functions from the specific changes
  // to a particular output value.  This is a functor with mapActionsInner
  // which allows the actions to be lifted into their parents actions
  // when needed
  type actionsInner<'a>
  let actionsInner: actionsInner<changeInner>
  let mapActionsInner: (actionsInner<'a>, 'a => 'b) => actionsInner<'b>

  let toEnumInner: inner => Store.enum
  let reduceSet: (contextInner, Dynamic.t<inner>, Indexed.t<unit>, input) => Dynamic.t<inner>
  let reduceInner: (
    contextInner,
    Dynamic.t<inner>,
    Indexed.t<unit>,
    changeInner,
  ) => Dynamic.t<inner>
  let inputInner: inner => input
  let showInner: inner => string
  let printErrorInner: inner => option<string>
}

module Context = FieldVector.Context

module Either0 = {
  // TODO: Could be reduced to not use Either at all? - AxM
  type input = () 
  type inner = () 
  type output = () 
  type error = FieldVector.error

  type t = Store.t<inner, output, error>
  type validate = FieldVector.validateOut<output>

  type contextInner = () 
  type context = ()

  let inputInner = () => ()
  let input = (_store: t) => ()
  let showInput = () => ""
  
  let setInner: input => inner = () => ()
  let set = (): t => Store.valid((), ())
  
  let emptyInner = (): inner => ()
  let empty = (): inner => ()
  
  let initInner = (_context: contextInner) => ()
  let init = () => Store.valid((), ())
  
  let hasEnum = (_x, e) => e == #Valid

  let validateInner = (_force, _context: contextInner, inner: inner) => { empty()->Dynamic.return }
  let validate = (_force, _context: context, store: t) => init()->Dynamic.return

  let inner = _ => ()
  
  let enum = _ => #Valid
  let outputInner = (_inner: inner) => Some()
  let output = _ => Some()
  let error = Store.error
  let printError = (_t: t) => None
  let printErrorInner = () => None

  type changeInner = unit
  let showChangeInner = (_c: changeInner): string => ""

  type change = unit
  let showChange = (_c: change): string => ""
  let makeSet = () => ()

  let toEnumInner = (_t: inner) => #Valid

  type actionsInner<'a> = unit
  let actionsInner: actionsInner<changeInner> = ()
  let mapActionsInner = (_actions: actionsInner<'a>, _fn): actionsInner<'b> => ()

  type actions<'change> = unit
  let mapActions = (_actions, _fn) => ()
  let actions: actions<change> = ()

  let showInner = (_inner: inner): string => ""

  let show = (_store: t): string => "Either0"

  // We're counting on these streams producing values, so we cant just return the existing inner/store Dynamics - AxM
  let reduceSet = ( _context: contextInner, inner: Dynamic.t<inner>, _change: Indexed.t<unit>, _input: input) => ()->Dynamic.return
  let reduceInner = ( _context: contextInner, _inner: Dynamic.t<inner>, _change: Indexed.t<unit>, _ch: changeInner) => ()->Dynamic.return
  let reduce = (~context: context, store: Dynamic.t<t>, _change: Indexed.t<change>) => init()->Dynamic.return

}

module Rec = {
  //Sum needs Product for maintaining context
  module Make = (S: Interface, Head: Field.T, Tail: Tail) => {
    type input = Either.t<Head.input, Tail.input>
    type inner = Either.t<Head.t, Tail.inner>
    type output = Either.t<Head.output, Tail.output>
    type error = FieldVector.error
    type t = Store.t<inner, output, error>
    type validate = FieldVector.validateOut<output>

    type contextInner = (Head.context, Tail.contextInner)
    type context = Context.t<input, validate, contextInner>

    let showInput = (input: input): string => {
      switch input {
      | Left(a) => `Left(${a->Head.showInput})`
      | Right(b) => `Right(${b->Tail.showInput})`
      }
    }

    let setInner = Either.bimap(Head.set, Tail.setInner)

    // prefer a context given empty value over const A
    let emptyInner = (context): inner => {
      let (contextHead, _) = context
      Either.Left(Head.init(contextHead))
    }

    let empty = (context: context) => {
      context.empty->Option.map(setInner)->Option.or(emptyInner(context.inner))
    }

    let initInner = (context: contextInner) => context->emptyInner
    let init = context => context->empty->Store.init

    let set = (x: input): t => x->setInner->Store.dirty

    let makeStore = (inner: inner): Dynamic.t<t> => {
      let output = inner->Either.bimap(Head.output, Tail.outputInner, _)->Either.sequence
      let enum = inner->Either.either(Head.enum, Tail.toEnumInner, _)
      [
        output->Option.map(output => Store.valid(inner, output)->Dynamic.return),
        enum == #Init ? Store.init(inner)->Dynamic.return->Some : None,
        enum == #Invalid ? Store.invalid(inner, #Part)->Dynamic.return->Some : None,
      ]
      ->Array.reduce(Option.first, None)
      ->Option.or(Store.dirty(inner)->Dynamic.return)
    }

    let validateInner = (force, context: contextInner, inner: inner): Dynamic.t<inner> => {
      let (contextHead, contextTail) = context
      switch inner {
      | Left(a) => a->Head.validate(force, contextHead, _)->Dynamic.map(Either.left)
      | Right(b) => b->Tail.validateInner(force, contextTail, _)->Dynamic.map(Either.right)
      }
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      validateInner(force, context.inner, store->Store.inner)->Dynamic.bind(makeStore)
    }

    type changeInner = Either.t<Head.change, Tail.changeInner>
    let showChangeInner = (change: changeInner): string => {
      switch change {
      | Left(a) => `Left(${Head.showChange(a)})`
      | Right(b) => `Right(${Tail.showChangeInner(b)})`
      }
    }

    type change = FieldVector.Change.t<input, changeInner>
    let showChange = (change: change): string =>
      change->FieldVector.Change.bimap(showInput, showChangeInner, _)->FieldVector.Change.show
    let makeSet = input => #Set(input)

    // A Nested tupe managing the "Inner" actions alone, for this head and tail
    type actionsInner<'a> = (Head.change => 'a, Tail.actionsInner<'a>)
    let actionsInner: actionsInner<changeInner> = (
      Either.left,
      Tail.actionsInner->Tail.mapActionsInner(Either.right),
    )
    let mapActionsInner = (actions: actionsInner<'a>, fn): actionsInner<'b> => {
      let (head, tail) = actions
      (a => fn(head(a)), Tail.mapActionsInner(tail, fn))
    }

    // Application of actionsInner into our own local Actions, for direct clients of FieldEither.
    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions, fn) => Actions.trimap(actions, x => x, fn, mapActionsInner(_, fn))
    let actions: actions<change> = {
      set: makeSet,
      clear: () => #Clear,
      inner: actionsInner->mapActionsInner(x => #Inner(x)),
      validate: () => #Validate,
    }

    let reduceSet = (
      context: contextInner,
      inner: Dynamic.t<inner>,
      change: Indexed.t<unit>,
      input: input,
    ): Dynamic.t<inner> => {
      let (contextHead, contextTail) = context
      switch input {
      | Left(a) => {
          let innerHead = inner->Dynamic.map(i =>
            switch i {
            | Left(a) => a
            | _ => Head.init(contextHead)
            }
          )
          change
          ->Indexed.const(a->Head.makeSet)
          ->Head.reduce(~context=contextHead, innerHead, _)
          ->Dynamic.map(Either.left)
        }
      | Right(inputTail) => {
          let innerTail = inner->Dynamic.map(x =>
            switch x {
            | Right(b) => b
            | _ => Tail.initInner(contextTail)
            }
          )
          Tail.reduceSet(contextTail, innerTail, change, inputTail)->Dynamic.map(Either.right)
        }
      }
    }

    let reduceInnerHead = (
      context: contextInner,
      inner: Dynamic.t<inner>,
      change: Indexed.t<unit>,
      ch: Head.change,
    ) => {
      let (contextHead, _) = context
      let innerHead = inner->Dynamic.map(i => {
        switch i {
        | Left(a) => a
        | _ => Head.init(contextHead)
        }
      })
      change
      ->Indexed.const(ch)
      ->Head.reduce(~context=contextHead, innerHead, _)
      ->Dynamic.map(Either.left)
    }

    let reduceInnerTail = (
      context: contextInner,
      inner: Dynamic.t<inner>,
      change: Indexed.t<unit>,
      ch: Tail.changeInner,
    ) => {
      let (_, contextTail) = context
      let innerTail = inner->Dynamic.map(i =>
        switch i {
        | Right(a) => a
        | _ => Tail.initInner(contextTail)
        }
      )
      Tail.reduceInner(contextTail, innerTail, change, ch)->Dynamic.map(Either.right)
    }

    let reduceInner = (
      context: contextInner,
      inner: Dynamic.t<inner>,
      change: Indexed.t<unit>,
      changeInner: changeInner,
    ) => {
      switch changeInner {
      | Left(ch) => reduceInnerHead(context, inner, change, ch)
      | Right(ch) => reduceInnerTail(context, inner, change, ch)
      }
    }

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<
      t,
    > => {
      let inner = store->Dynamic.map(Store.inner)
      switch change.value {
      | #Clear => context->init->Dynamic.return
      | #Set(input) =>
        reduceSet(context.inner, inner, change->Indexed.const(), input)->Dynamic.bind(makeStore)
      | #Inner(changeInner) =>
        reduceInner(context.inner, inner, change->Indexed.const(), changeInner)->Dynamic.bind(
          makeStore,
        )
      | #Validate => store->Dynamic.take(1)->Dynamic.bind(store => validate(true, context, store))
      }
    }

    let makeSet = input => #Set(input)

    let inner = Store.inner

    let inputInner = (inner: inner) => inner->Either.bimap(Head.input, Tail.inputInner, _)
    let input = (store: t) => store->Store.inner->inputInner

    let outputInner = (inner: inner) =>
      inner->Either.bimap(Head.output, Tail.outputInner, _)->Either.sequence
    let output = Store.output

    let error = Store.error

    let enum = Store.toEnum
    let toEnumInner = Either.either(Head.enum, Tail.toEnumInner, _)

    let showInner = (inner: inner): string =>
      inner
      ->Either.bimap(Head.show, Tail.showInner, _)
      ->Either.either(x => `Left: ${x}`, x => `Right: ${x}`, _)

    let show = (store: t): string => {
      `EitherRec: {
        inner: ${store->Store.inner->showInner}
      }`
    }

    let printErrorInner = (inner: inner): option<string> =>
      inner->Either.either(Head.printError, Tail.printErrorInner, _)

    let printError = (store: t) => {
      store->Store.error->Option.bind(_error => store->Store.inner->printErrorInner)
    }
  }
}

module Either1 = {
  type either<'a> = Either.Nested.t1<'a>
  type tuple<'a> = Tuple.Nested.tuple1<'a>
  module Make = (I: Interface, A: Field.T): (
    Tail
      with type input = either<A.input>
      and type output = either<A.output>
      and type inner = either<A.t>
      and type contextInner = tuple<A.context>
      and type context = Context.t<
        either<A.input>,
        FieldVector.validateOut<either<A.output>>,
        tuple<A.context>,
      >
      and type t = Store.t<either<A.t>, either<A.output>, error>
      and type changeInner = either<A.change>
      and type change = FieldVector.Change.t<either<A.input>, either<A.change>>
      and type actionsInner<'a> = tuple<A.change => 'a>
  ) => Rec.Make(I, A, Either0)
}

module Either2 = {
  type either<'a, 'b> = Either.Nested.t2<'a, 'b>
  type tuple<'a, 'b> = Tuple.Nested.tuple2<'a, 'b>
  module Make = (I: Interface, A: Field.T, B: Field.T): (
    Tail
      with type input = either<A.input, B.input>
      and type output = either<A.output, B.output>
      and type inner = either<A.t, B.t>
      and type contextInner = tuple<A.context, B.context>
      and type context = Context.t<
        Either.Nested.t2<A.input, B.input>,
        FieldVector.validateOut<either<A.output, B.output>>,
        tuple<A.context, B.context>,
      >
      and type t = Store.t<either<A.t, B.t>, either<A.output, B.output>, error>
      and type changeInner = either<A.change, B.change>
      and type change = FieldVector.Change.t<either<A.input, B.input>, either<A.change, B.change>>
      and type actionsInner<'a> = tuple<A.change => 'a, B.change => 'a>
  ) => Rec.Make(I, A, Either1.Make(I, B))
}

module Either3 = {
  type either<'a, 'b, 'c> = Either.Nested.t3<'a, 'b, 'c>
  type tuple<'a, 'b, 'c> = Tuple.Nested.tuple3<'a, 'b, 'c>
  module Make = (I: Interface, A: Field.T, B: Field.T, C: Field.T): (
    Tail
      with type input = either<A.input, B.input, C.input>
      and type output = either<A.output, B.output, C.output>
      and type inner = either<A.t, B.t, C.t>
      and type contextInner = (A.context, Tuple.Nested.Tuple2.t<B.context, C.context>)
      and type context = Context.t<
        Either.Nested.t3<A.input, B.input, C.input>,
        FieldVector.validateOut<either<A.output, B.output, C.output>>,
        tuple<A.context, B.context, C.context>,
      >
      and type t = Store.t<either<A.t, B.t, C.t>, either<A.output, B.output, C.output>, error>
      and type changeInner = Either.t<A.change, Either.t<B.change, Either.t<C.change, unit>>>
      and type change = FieldVector.Change.t<
        either<A.input, B.input, C.input>,
        either<A.change, B.change, C.change>,
      >
      and type actionsInner<'a> = (
        A.change => 'a,
        Tuple.Nested.Tuple2.t<B.change => 'a, C.change => 'a>,
      )
  ) => Rec.Make(I, A, Either2.Make(I, B, C))
}

module Either4 = {
  type either<'a, 'b, 'c, 'd> = Either.Nested.t4<'a, 'b, 'c, 'd>
  module Make = (I: Interface, A: Field.T, B: Field.T, C: Field.T, D: Field.T): (
    Tail
      with type input = either<A.input, B.input, C.input, D.input>
      and type inner = either<A.t, B.t, C.t, D.t>
      and type output = either<A.output, B.output, C.output, D.output>
      and type contextInner = (A.context, Tuple.Nested.Tuple3.t<B.context, C.context, D.context>)
      and type context = Context.t<
        either<A.input, B.input, C.input, D.input>,
        FieldVector.validateOut<either<A.output, B.output, C.output, D.output>>,
        (A.context, Tuple.Nested.Tuple3.t<B.context, C.context, D.context>),
      >
      and type t = Store.t<
        either<A.t, B.t, C.t, D.t>,
        either<A.output, B.output, C.output, D.output>,
        error,
      >
      and type changeInner = either<A.change, B.change, C.change, D.change>
      and type change = FieldVector.Change.t<
        either<A.input, B.input, C.input, D.input>,
        either<A.change, B.change, C.change, D.change>,
      >
      and type actionsInner<'a> = (
        A.change => 'a,
        Tuple.Nested.Tuple3.t<B.change => 'a, C.change => 'a, D.change => 'a>,
      )
  ) => Rec.Make(I, A, Either3.Make(I, B, C, D))
}

module Either5 = {
  type either<'a, 'b, 'c, 'd, 'e> = Either.Nested.t5<'a, 'b, 'c, 'd, 'e>
  module Make = (I: Interface, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T): (
    Tail
      with type input = either<A.input, B.input, C.input, D.input, E.input>
      and type inner = either<A.t, B.t, C.t, D.t, E.t>
      and type output = either<A.output, B.output, C.output, D.output, E.output>
      and type contextInner = (
        A.context,
        Tuple.Nested.Tuple4.t<B.context, C.context, D.context, E.context>,
      )
      and type context = Context.t<
        either<A.input, B.input, C.input, D.input, E.input>,
        FieldVector.validateOut<either<A.output, B.output, C.output, D.output, E.output>>,
        (A.context, Tuple.Nested.Tuple4.t<B.context, C.context, D.context, E.context>),
      >
      and type t = Store.t<
        either<A.t, B.t, C.t, D.t, E.t>,
        either<A.output, B.output, C.output, D.output, E.output>,
        error,
      >
      and type changeInner = either<A.change, B.change, C.change, D.change, E.change>
      and type change = FieldVector.Change.t<
        either<A.input, B.input, C.input, D.input, E.input>,
        either<A.change, B.change, C.change, D.change, E.change>,
      >
      and type actionsInner<'a> = (
        A.change => 'a,
        Tuple.Nested.Tuple4.t<B.change => 'a, C.change => 'a, D.change => 'a, E.change => 'a>,
      )
  ) => Rec.Make(I, A, Either4.Make(I, B, C, D, E))
}

module Either6 = {
  type either<'a, 'b, 'c, 'd, 'e, 'f> = Either.Nested.t6<'a, 'b, 'c, 'd, 'e, 'f>
  module Make = (I: Interface, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T): (
    Tail
      with type input = either<A.input, B.input, C.input, D.input, E.input, F.input>
      and type inner = either<A.t, B.t, C.t, D.t, E.t, F.t>
      and type output = either<A.output, B.output, C.output, D.output, E.output, F.output>
      and type contextInner = (
        A.context,
        Tuple.Nested.Tuple5.t<B.context, C.context, D.context, E.context, F.context>,
      )
      and type context = Context.t<
        either<A.input, B.input, C.input, D.input, E.input, F.input>,
        FieldVector.validateOut<either<A.output, B.output, C.output, D.output, E.output, F.output>>,
        (A.context, Tuple.Nested.Tuple5.t<B.context, C.context, D.context, E.context, F.context>),
      >
      and type t = Store.t<
        either<A.t, B.t, C.t, D.t, E.t, F.t>,
        either<A.output, B.output, C.output, D.output, E.output, F.output>,
        error,
      >
      and type changeInner = either<A.change, B.change, C.change, D.change, E.change, F.change>
      and type change = FieldVector.Change.t<
        either<A.input, B.input, C.input, D.input, E.input, F.input>,
        either<A.change, B.change, C.change, D.change, E.change, F.change>,
      >
      and type actionsInner<'a> = (
        A.change => 'a,
        Tuple.Nested.Tuple5.t<
          B.change => 'a,
          C.change => 'a,
          D.change => 'a,
          E.change => 'a,
          F.change => 'a,
        >,
      )
  ) => Rec.Make(I, A, Either5.Make(I, B, C, D, E, F))
}
