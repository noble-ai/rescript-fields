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
  let validateInner: (bool, contextInner, inner) => Rxjs.t<Rxjs.foreign, Rxjs.void,inner>

  // type changeInner
  // let showChangeInner: changeInner => string

  // actionsInner is a collection of functions from the specific changes
  // to a particular output value.  This is a functor with mapActionsInner
  // which allows the actions to be lifted into their parents actions
  // when needed
  type actionsInner<'a>
  // let actionsInner: actionsInner<changeInner>
  let mapActionsInner: (actionsInner<'a>, 'a => 'b) => actionsInner<'b>
  
  type partition
  @ocaml.doc("Takes the fields of a part instead of a part since we are having to deconstruct in the outer `split` to prepare inner values so why reconstruct")
  let splitInner: (inner, actionsInner<()>) => partition
  
  let makeDynInner: (contextInner, Rxjs.Observable.t<input>) => Dyn.t<Close.t<Form.t<inner, actionsInner<()>>>>

  let toEnumInner: inner => Store.enum
  // let reduceSet: (contextInner, Rxjs.t<Rxjs.foreign, Rxjs.void,inner>, Indexed.t<unit>, input) => Rxjs.t<Rxjs.foreign, Rxjs.void,inner>
//   let reduceInner: (
//     contextInner,
//     Rxjs.t<Rxjs.foreign, Rxjs.void,inner>,
//     Indexed.t<unit>,
//     changeInner,
//   ) => Rxjs.t<Rxjs.foreign, Rxjs.void,inner>
  let inputInner: inner => input
  let showInner: inner => string
  let printErrorInner: inner => option<string>
}

module Context = FieldVector.Context

module Either0 = {
  // Either0 is the terminal case of recursion in FieldEither.
  // Its degenerate, holds only unit value, and occupies the final Right value in the
  // Nested Eithers for state etc.
  // All real values are Left, nested into Rights to place them in context.

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

  let validateInner = (_force, _context: contextInner, _inner: inner) => { empty()->Dynamic.return }
  let validate = (_force, _context: context, _store: t) => init()->Dynamic.return

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
  // let actionsInner: actionsInner<changeInner> = ()
  let mapActionsInner = (_actions: actionsInner<'a>, _fn): actionsInner<'b> => ()

  type actions<'change> = unit
  let mapActions = (_actions, _fn) => ()
  // let actions: actions<change> = ()
  
  type pack = Form.t<t, actions<()>>

  type partition = ()
  let splitInner = (_, _) => {
    ()
  }
 
  let showInner = (_inner: inner): string => "(either0 inner)"

  let show = (_store: t): string => "Either0"

  type observables = 
    Rxjs.t<Rxjs.foreign, Rxjs.void, Form.t<t, actions<()>>>
  
  let makeDynInner =  (_context: contextInner, set: Rxjs.Observable.t<input>)
    : Dyn.t<Close.t<Form.t<inner, actionsInner<()>>>>
    => {
      // Since either0 is degenerate, it will never be meanigfully set
      // and it should never emit values on validation.

      let first: Close.t<Form.t<'f, 'a>> = {pack: {field: (), actions: ()}, close: () => ()}

      let dyn = set 
        // ->Dynamic.log("Either0 set")
        ->Dynamic.map(_ => Dynamic.return(first))

      {first, dyn}
    }

  let makeDyn = (_context: context, setOuter: Rxjs.Observable.t<input>, valOuter: option<Rxjs.Observable.t<()>> )
    : Dyn.t<Close.t<Form.t<t, actions<()>>>>
    => {
    let field = init()
    let actions: actions<()> = () 
    let first: Close.t<Form.t<'f, 'a>> = {pack: { field, actions }, close: () => ()}

    let dyn = 
      valOuter
      ->Option.map(Rxjs.merge2(setOuter, _))
      ->Option.or(setOuter)
      ->Dynamic.map(_ => Dynamic.return(first))
      ->Rxjs.toObservable

    {first, dyn}
  }


  // We're counting on these streams producing values, so we cant just return the existing inner/store Dynamics - AxM
  // let reduceSet = ( _context: contextInner, inner: Rxjs.t<Rxjs.foreign, Rxjs.void,inner>, _change: Indexed.t<unit>, _input: input) => ()->Dynamic.return
  // let reduceInner = ( _context: contextInner, _inner: Rxjs.t<Rxjs.foreign, Rxjs.void,inner>, _change: Indexed.t<unit>, _ch: changeInner) => ()->Dynamic.return
  // let reduce = (~context: context, store: Rxjs.t<Rxjs.foreign, Rxjs.void,t>, _change: Indexed.t<change>) => init()->Dynamic.return

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

    let makeStore = (inner: inner): t => {
      let output = inner->Either.bimap(Head.output, Tail.outputInner, _)->Either.sequence
      let enum = inner->Either.either(Head.enum, Tail.toEnumInner, _)
      [
        output->Option.map(output => Store.valid(inner, output)),
        enum == #Init ? Store.init(inner)->Some : None,
        enum == #Invalid ? Store.invalid(inner, #Part)->Some : None,
      ]
      ->Array.reduce(Option.first, None)
      ->Option.or(Store.dirty(inner))
    }

    let validateInner = (force, context: contextInner, inner: inner): Rxjs.t<Rxjs.foreign, Rxjs.void,inner> => {
      let (contextHead, contextTail) = context
      switch inner {
      | Left(a) => a->Head.validate(force, contextHead, _)->Dynamic.map(Either.left)
      | Right(b) => b->Tail.validateInner(force, contextTail, _)->Dynamic.map(Either.right)
      }
    }

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      validateInner(force, context.inner, store->Store.inner)->Dynamic.map(makeStore)
    }

    // A Nested tupe managing the "Inner" actions alone, for this head and tail
    type actionsInner<'change> = (Head.actions<'change>, Tail.actionsInner<'change>)

    let mapActionsInner = (actions: actionsInner<'a>, fn): actionsInner<'b> => {
      let (head, tail) = actions
      (head->Head.mapActions(fn), Tail.mapActionsInner(tail, fn))
    }

    // Application of actionsInner into our own local Actions, for direct clients of FieldEither.
    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions, fn) => Actions.trimap(actions, x => x, fn, mapActionsInner(_, fn))
  
    type pack = Form.t<t, actions<()>>

    type partition = Either.t<Form.t<Head.t, Head.actions<()>>, Tail.partition>
    let splitInner = (inner: inner, actions: actionsInner<'a>): partition => {
      let (ah, at) = actions
      inner->Either.bimap(
        (field) => ({field, actions: ah}: Form.t<Head.t, Head.actions<()>>),
        (tail) => Tail.splitInner(tail, at),
        _
      )
    }

    let split = (part: Form.t<t, actions<()>>): partition => {
      splitInner( part.field->Store.inner, part.actions.inner)
    }

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


    // Recursive elements of makeObservable
    let makeDynInner = (context: contextInner, set: Rxjs.Observable.t<input>)
      : Dyn.t<Close.t<Form.t<inner, actionsInner<()>>>>
      => {
      let (contextHead, contextTail) = context
      let setHead = set->Dynamic.keepMap(Either.toLeft)//->Dynamic.log("setHead")
      let setTail  = set->Dynamic.keepMap(Either.toRight)//->Dynamic.log("setTail")

      let {first: firstHead, dyn: dynHead } = Head.makeDyn(contextHead, setHead->Rxjs.toObservable, None)
      let dynHead = dynHead
        ->Dynamic.startWith(Dynamic.return(firstHead))
        // ->Rxjs.pipe(Rxjs.share())
        // ->Dynamic.tap(Dynamic.log_(_, "head"))

      // FIXME: Sould all dyns be required to emit a first observable as well as include a first value?
      let {first: firstTail, dyn: dynTail } = Tail.makeDynInner(contextTail, setTail)
      // let dynTail = dynTail->Dynamic.startWith(Dynamic.return(firstTail))

      // FIXME: take correct value for initial field?
      let field: inner = Left(firstHead.pack->Form.field) //, packTail->Form.field)
      let actions: actionsInner<()> = (firstHead.pack->Form.actions, firstTail.pack->Form.actions)
      let close = () => {
        firstTail.close()
        firstHead.close()
      }

      let packFirst: Form.t<'f, 'a> = { field, actions }
      let first: Close.t<Form.t<'f, 'a>> = { pack: packFirst, close }

      let dynActionsHead = 
        dynHead
        ->Dynamic.switchMap(Dynamic.map(_,  head => head.pack.actions))
        ->Dynamic.startWith(firstHead.pack.actions)
        // ->Dynamic.log("dynActionsHead")

      let dynActionsTail = 
        dynTail
        ->Dynamic.switchMap(Dynamic.map(_, tail => tail.pack.actions))
        ->Dynamic.startWith(firstTail.pack.actions)
        // ->Dynamic.log("dynActionsTail")

      let dynActions = 
            Rxjs.combineLatest2(dynActionsHead, dynActionsTail)
            ->Dynamic.startWith(actions)
            // ->Rxjs.pipe(Rxjs.shareReplay(1))
            // ->Dynamic.log("dynActions")

      let dynCloseHead = 
        dynHead
        ->Dynamic.switchMap( Dynamic.map(_, Close.close))
      //   ->Dynamic.startWith(firstHead.close)
      //   ->Rxjs.pipe(Rxjs.shareReplay(1))
        // ->Dynamic.log("dynCloseHead")

      let dynCloseTail = 
        dynTail
        ->Dynamic.switchMap(Dynamic.map(_, Close.close))
      //   ->Dynamic.startWith(firstTail.close)
      //   ->Rxjs.pipe(Rxjs.shareReplay(1))
        // ->Dynamic.log("dynCloseTail")

      let dynClose: Rxjs.t<Rxjs.foreign, Rxjs.void,() => ()> = 
        Rxjs.combineLatest2(dynCloseHead, dynCloseTail)
        ->Dynamic.map( ((closeHead, closeTail)) => {
          () => {
            closeHead()
            closeTail()
          }
        })
        ->Dynamic.startWith(close)

      // Head and Tail both produce their own dyns
      // As an Sum type, we are trying to produce only one or the other value at any moment
      // But we still want to produce actions and close for both.

      let dynFieldHead = 
        dynHead
        ->Dynamic.map(Dynamic.map(_, head => head.pack.field->Either.left))

      let dynFieldTail = 
        dynTail
        ->Dynamic.map(Dynamic.map(_, tail => tail.pack.field->Either.right))

      let dyn = Rxjs.merge2( dynFieldHead, dynFieldTail)
        ->Dynamic.map( field => {
          field 
          ->Dynamic.withLatestFrom2(dynActions, dynClose)
          ->Dynamic.map( ((field, actions, close)): Close.t<Form.t<'f, 'a>> => {pack: {field, actions}, close })
          // FIXME: should start with latest left pack?
        })
        ->Dynamic.startWith(Dynamic.return(first))

      {first, dyn}
    }

    let applyInner = (inner: Rxjs.Observable.t<Close.t<Form.t<inner, actionsInner<()>>>>, actions, closeOpt) => {
      inner
      ->Dynamic.map(({pack}): Close.t<Form.t<t, actions<()>>> => {
        let field = pack.field->makeStore
        let actions: actions<()> = {
          ...actions,
          inner: pack.actions
        }

        let close = closeOpt
        // () => {
        //   closeInner()
        //   closeOpt()
        // }
        {pack: { field, actions }, close}
      })
    }


    // Non-Recursive makeObservable
    let makeDyn = (context: context, setOuter: Rxjs.Observable.t<input>, valOuter: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      let setInner = Rxjs.Subject.makeEmpty()
      let clearInner = Rxjs.Subject.makeEmpty()
      let opt = Rxjs.Subject.makeEmpty()
      let valInner = Rxjs.Subject.makeEmpty() 
      let complete = Rxjs.Subject.makeEmpty()

      let setOpt = opt->Rxjs.pipe(Rxjs.keepMap(x => x))//->Dynamic.log("setOpt")
      let clearOpt = opt->Rxjs.pipe(Rxjs.keepMap(Option.invert(_, ())))

      let val = valOuter->Option.map(Rxjs.merge2(_, valInner))->Option.or(valInner->Rxjs.toObservable)
      let set = Rxjs.merge3(setOuter, setInner, setOpt)//->Dynamic.log("set")
      let clear = Rxjs.merge2(clearInner, clearOpt)

      let {first: firstInner, dyn: dynInner} = makeDynInner(context.inner, set)
      let field = firstInner.pack->Form.field->Store.init //->makeStore
    
      let state = Rxjs.Subject.makeBehavior(field)

      let actions: actions<()> = {
        clear: Rxjs.next(clearInner), 
        set: Rxjs.next(setInner),
        opt: Rxjs.next(opt),
        inner: firstInner.pack->Form.actions,
        validate: Rxjs.next(valInner),
      }

      let close = Rxjs.next(complete)
    
      let first: Close.t<Form.t<t, 'a>> = {pack: { field, actions }, close}

      let memoState = Dynamic.map(_, Dynamic.tap(_, (x: Close.t<Form.t<t, 'a>>) => Rxjs.next(state, x.pack.field)))

      let changes = Rxjs.merge2(
        clear->Dynamic.map(_ => Dynamic.return(first))->memoState,
        dynInner->Dynamic.map(applyInner(_, actions, close))->memoState
      )

      let validated = val 
        ->Dynamic.withLatestFrom(state)
        ->Dynamic.map( ((_validation, field)) => {
          validate(false, context, field)
          ->Dynamic.map((field): Close.t<Form.t<'f, 'a>> => {pack: {field, actions}, close})
        })

      // Any single value from changes interrupts a validation sequence  
      let dyn = 
        Rxjs.merge2(changes, validated)
        ->Rxjs.pipe(Rxjs.takeUntil(complete))

      {first, dyn}
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
      // and type changeInner = either<A.change>
      // and type change = FieldVector.Change.t<either<A.input>, either<A.change>>
      and type actionsInner<'a> = tuple<A.actions<'a>>
      and type actions<'change> = Actions.t<either<A.input>, 'change, tuple<A.actions<'change>>>
      and type partition = either<Form.t<A.t, A.actions<()>>>
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
      // and type changeInner = either<A.change, B.change>
      // and type change = FieldVector.Change.t<either<A.input, B.input>, either<A.change, B.change>>
      and type actionsInner<'a> = tuple<A.actions<'a>, B.actions<'a>>
      and type actions<'change> = Actions.t<either<A.input, B.input>, 'change, tuple<A.actions<'change>, B.actions<'change>>>
      and type partition = either<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>
        >
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
      // and type changeInner = Either.t<A.change, Either.t<B.change, Either.t<C.change, unit>>>
      // and type change = FieldVector.Change.t<
      //   either<A.input, B.input, C.input>,
      //   either<A.change, B.change, C.change>,
      // >
      and type actionsInner<'a> = tuple<
        A.actions<'a>,
        B.actions<'a>,
        C.actions<'a>
      >
      and type actions<'change> = Actions.t<either<A.input, B.input, C.input>, 'change, tuple<A.actions<'change>, B.actions<'change>, C.actions<'change>>>
      and type partition = either<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>
      >
  ) => Rec.Make(I, A, Either2.Make(I, B, C))
}

module Either4 = {
  type either<'a, 'b, 'c, 'd> = Either.Nested.t4<'a, 'b, 'c, 'd>
  type tuple<'a, 'b, 'c, 'd> = Tuple.Nested.tuple4<'a, 'b, 'c, 'd>
  module Make = (I: Interface, A: Field.T, B: Field.T, C: Field.T, D: Field.T): (
    Tail
      with type input = either<A.input, B.input, C.input, D.input>
      and type inner = either<A.t, B.t, C.t, D.t>
      and type output = either<A.output, B.output, C.output, D.output>
      and type contextInner = tuple<A.context, B.context, C.context, D.context>
      and type context = Context.t<
        either<A.input, B.input, C.input, D.input>,
        FieldVector.validateOut<either<A.output, B.output, C.output, D.output>>,
        tuple<A.context, B.context, C.context, D.context>
      >
      and type t = Store.t<
        either<A.t, B.t, C.t, D.t>,
        either<A.output, B.output, C.output, D.output>,
        error,
      >
      // and type changeInner = either<A.change, B.change, C.change, D.change>
      // and type change = FieldVector.Change.t<
      //   either<A.input, B.input, C.input, D.input>,
      //   either<A.change, B.change, C.change, D.change>,
      // >
      and type actionsInner<'a> = Tuple.Nested.Tuple4.t<
        A.actions<'a>,
        B.actions<'a>,
        C.actions<'a>,
        D.actions<'a>
      >
      and type actions<'change> = Actions.t<
        either<A.input, B.input, C.input, D.input>,
        'change,
         tuple<A.actions<'change>, B.actions<'change>, C.actions<'change>, D.actions<'change>>>
      and type partition = either<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>
      >
  ) => Rec.Make(I, A, Either3.Make(I, B, C, D))
}

module Either5 = {
  type either<'a, 'b, 'c, 'd, 'e> = Either.Nested.t5<'a, 'b, 'c, 'd, 'e>
  type tuple<'a, 'b, 'c, 'd, 'e> = Tuple.Nested.tuple5<'a, 'b, 'c, 'd, 'e>
  module Make = (I: Interface, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T): (
    Tail
      with type input = either<A.input, B.input, C.input, D.input, E.input>
      and type inner = either<A.t, B.t, C.t, D.t, E.t>
      and type output = either<A.output, B.output, C.output, D.output, E.output>
      and type contextInner = tuple<
        A.context, B.context, C.context, D.context, E.context
      >
      and type context = Context.t<
        either<A.input, B.input, C.input, D.input, E.input>,
        FieldVector.validateOut<either<A.output, B.output, C.output, D.output, E.output>>,
        tuple<A.context, B.context, C.context, D.context, E.context>,
      >
      and type t = Store.t<
        either<A.t, B.t, C.t, D.t, E.t>,
        either<A.output, B.output, C.output, D.output, E.output>,
        error,
      >
      // and type changeInner = either<A.change, B.change, C.change, D.change, E.change>
      // and type change = FieldVector.Change.t<
      //   either<A.input, B.input, C.input, D.input, E.input>,
      //   either<A.change, B.change, C.change, D.change, E.change>,
      // >
      and type actionsInner<'a> = tuple< 
        A.actions<'a>,
        B.actions<'a>,
        C.actions<'a>,
        D.actions<'a>,
        E.actions<'a>
      >
      and type actions<'change> = Actions.t<
        either<A.input, B.input, C.input, D.input, E.input>,
        'change,
         tuple<A.actions<'change>, B.actions<'change>, C.actions<'change>, D.actions<'change>, E.actions<'change>>>
      and type partition = either<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>,
        Form.t<E.t, E.actions<()>>
      >
  ) => Rec.Make(I, A, Either4.Make(I, B, C, D, E))
}

module Either6 = {
  type either<'a, 'b, 'c, 'd, 'e, 'f> = Either.Nested.t6<'a, 'b, 'c, 'd, 'e, 'f>
  type tuple<'a, 'b, 'c, 'd, 'e, 'f> = Tuple.Nested.tuple6<'a, 'b, 'c, 'd, 'e, 'f>
  module Make = (I: Interface, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T): (
    Tail
      with type input = either<A.input, B.input, C.input, D.input, E.input, F.input>
      and type inner = either<A.t, B.t, C.t, D.t, E.t, F.t>
      and type output = either<A.output, B.output, C.output, D.output, E.output, F.output>
      and type contextInner = tuple<
        A.context, B.context, C.context, D.context, E.context, F.context
      >
      and type context = Context.t<
        either<A.input, B.input, C.input, D.input, E.input, F.input>,
        FieldVector.validateOut<either<A.output, B.output, C.output, D.output, E.output, F.output>>,
        tuple<A.context, B.context, C.context, D.context, E.context, F.context>,
      >
      and type t = Store.t<
        either<A.t, B.t, C.t, D.t, E.t, F.t>,
        either<A.output, B.output, C.output, D.output, E.output, F.output>,
        error,
      >
      // and type changeInner = either<A.change, B.change, C.change, D.change, E.change, F.change>
      // and type change = FieldVector.Change.t<
      //   either<A.input, B.input, C.input, D.input, E.input, F.input>,
      //   either<A.change, B.change, C.change, D.change, E.change, F.change>,
      // >
      and type actionsInner<'a> = tuple<
          A.actions<'a>,
          B.actions<'a>,
          C.actions<'a>,
          D.actions<'a>,
          E.actions<'a>,
          F.actions<'a>
        >
      and type actions<'change> = Actions.t<
        either<A.input, B.input, C.input, D.input, E.input, F.input>,
        'change,
         tuple<A.actions<'change>, B.actions<'change>, C.actions<'change>, D.actions<'change>, E.actions<'change>, F.actions<'change>>>
      and type partition = either<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>,
        Form.t<E.t, E.actions<()>>,
        Form.t<F.t, F.actions<()>>
      >
  ) => Rec.Make(I, A, Either5.Make(I, B, C, D, E, F))
}
