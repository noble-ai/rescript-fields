open FieldProduct

@@ocamldoc("FieldSum is a decoratin of FieldEither that allows you to map to your own sum type
as your input and output structures 
All the dynamic behavior is in FieldEither.
")

module Sum1 = {
  module Tuple = Product1.Tuple
  module T = Product1.T

  type sum<'a> = Product1.PolyVariant.t<'a>

  module type Interface = {
    // A variant type that has values of our own choosing
    type t<'a>
    let toSum: t<'a> => sum<'a>
    let fromSum: sum<'a> => t<'a>
  }

  module Context = FieldEither.Context

  module type T = {
    include Field.T
    type parted
    type pack
    let split: pack => parted
  }

  // giving the Make functor this
  module type Make = (S: Interface, P: Product1.Generic, A: Field.T) =>
  (
    T
      with type input = S.t<A.input>
      and type inner = S.t<A.t>
      and type output = S.t<A.output>
      and type error = error
      and type t = Store.t<S.t<A.t>, S.t<A.output>, error>
      and type context = Context.t<
        S.t<A.input>,
        FieldVector.validateOut<S.t<A.output>>,
        P.structure<A.context>,
      >
      and type actions<'change> = FieldVector.Actions.t<
        S.t<A.input>,
        'change,
        P.structure<A.actions<'change>>,
      >
      and type pack = Form.t<
        Store.t<S.t<A.t>, S.t<A.output>, error>,
        FieldVector.Actions.t<S.t<A.input>, unit, P.structure<A.actions<unit>>>,
      >
      and type parted = S.t<Form.t<A.t, A.actions<unit>>>
  )

  //Sum needs Product for maintaining context
  module Make: Make = (S: Interface, P: Product1.Generic, A: Field.T) => {
    module T = Product1.T
    module Inner = FieldEither.Either1.Make(A)
    type either<'a> = Either.Nested.t1<'a>

    type input = S.t<A.input>
    type inner = S.t<A.t>
    type output = S.t<A.output>
    type error = [#Whole(string) | #Part]

    type t = Store.t<inner, output, error>

    type validate = FieldVector.validateOut<output>
    type contextInner = P.structure<A.context>
    type context = Context.t<input, validate, contextInner>

    // Context is the product equivalent of this sum, so we need toTuple in some places
    let toTuple: P.structure<'a> => T.t<'a> = x => P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a> => P.structure<'a> = x => x->T.decode->P.fromTuple

    let toEither: S.t<'a> => either<'a> = s => s->S.toSum->Product1.PolyVariant.toEither
    let fromEither: either<'a> => S.t<'a> = x => x->Product1.PolyVariant.fromEither->S.fromSum

    let storeToSum: Inner.t => t = Store.bimap(_, fromEither, fromEither)
    let storeToEither: t => Inner.t = Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, (v, out) => out->fromEither->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty: option<Inner.input> = context.empty->Option.map(toEither)
      let validate = context.validate->validateToEither
      {?empty, ?validate, inner}
    }

    let showInput: input => string = x => x->toEither->Inner.showInput

    // prefer a context given empty value over const A
    let empty: context => inner = context => context->contextToTuple->Inner.empty->fromEither
    let init = context => context->empty->Store.init
    let set: input => t = x => x->toEither->Inner.set->storeToSum
    let show: t => string = store => store->storeToEither->Inner.show

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)->Dynamic.map(storeToSum)
    }

    type actionsInner<'out> = P.structure<A.actions<'out>>
    let mapActionsInner: (actionsInner<'ch>, 'ch => 'b) => actionsInner<'b> = (ac, fn) =>
      ac->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions: (actions<'change>, 'change => 'b) => actions<'b> = (actions, fn) =>
      actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    type pack = Form.t<t, actions<unit>>
    type parted = S.t<Form.t<A.t, A.actions<unit>>>

    let split: Form.t<t, actions<unit>> => parted = part => {
      Inner.splitInner(part.field->Store.inner->toEither, part.actions.inner->toTuple)->fromEither
    }
    
    let actionsFromVector: Inner.actions<()> => actions<()> = FieldVector.Actions.trimap(_, toEither, x=>x, fromTuple)
    let packFromEither = Form.bimap(_, storeToSum, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toEither), set->Dynamic.map(toEither), val)
      ->Dyn.map(Close.map(_, packFromEither))
    }
  
    let input = (store: t): input => store->storeToEither->Inner.input->fromEither
    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = store => store->storeToEither->Inner.printError
  }
}

module Sum2 = {
  module Tuple = Product1.Tuple
  module T = Product1.T
  type sum<'a, 'b> = Product2.PolyVariant.t<'a, 'b>

  module type Interface = {
    // A variant type that has values of our own choosing
    type t<'a, 'b>
    let toSum: t<'a, 'b> => sum<'a, 'b>
    let fromSum: sum<'a, 'b> => t<'a, 'b>
  }

  module Context = FieldEither.Context

  module type T = {
    include Field.T
    type parted
    type pack
    let split: pack => parted
  }

  // giving the Make functor this
  module type Make = (S: Interface, P: Product2.Generic, A: Field.T, B: Field.T) =>
  (
    T
      with type input = S.t<A.input, B.input>
      and type inner = S.t<A.t, B.t>
      and type output = S.t<A.output, B.output>
      and type error = error
      and type t = Store.t<S.t<A.t, B.t>, S.t<A.output, B.output>, error>
      and type context = Context.t<
        S.t<A.input, B.input>,
        FieldVector.validateOut<S.t<A.output, B.output>>,
        P.structure<A.context, B.context>,
      >
      and type actions<'change> = FieldVector.Actions.t<
        S.t<A.input, B.input>,
        'change,
        P.structure<A.actions<'change>, B.actions<'change>>,
      >
      and type pack = Form.t<
        Store.t<S.t<A.t, B.t>, S.t<A.output, B.output>, error>,
        FieldVector.Actions.t<
          S.t<A.input, B.input>,
          unit,
          P.structure<A.actions<unit>, B.actions<unit>>,
        >,
      >
      and type parted = S.t<Form.t<A.t, A.actions<unit>>, Form.t<B.t, B.actions<unit>>>
  )

  //Sum needs Product for maintaining context
  module Make: Make = (S: Interface, P: Product2.Generic, A: Field.T, B: Field.T) => {
    module T = Product2.T
    module Inner = FieldEither.Either2.Make(A, B)
    type either<'a, 'b> = Either.Nested.t2<'a, 'b>

    type input = S.t<A.input, B.input>
    type inner = S.t<A.t, B.t>
    type output = S.t<A.output, B.output>
    type error = [#Whole(string) | #Part]

    type t = Store.t<inner, output, error>

    type validate = FieldVector.validateOut<output>
    type contextInner = P.structure<A.context, B.context>
    type context = Context.t<input, validate, contextInner>

    // Context is x->S.toSum->FieldProduct.Product1.PolyVariant.toEither
    let toTuple: P.structure<'a, 'b> => T.t<'a, 'b> = x => P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b> => P.structure<'a, 'b> = x => x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b>): either<'a, 'b> => s->S.toSum->Product2.PolyVariant.toEither
    let fromEither: either<'a, 'b> => S.t<'a, 'b> = x =>
      x->Product2.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither = Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, (v, out) => out->fromEither->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty: option<Inner.input> = context.empty->Option.map(toEither)
      let validate = context.validate->validateToEither
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toEither->Inner.showInput

    // prefer a context given empty value over const A
    let empty = (context: context) => context->contextToTuple->Inner.empty->fromEither
    let init = context => context->empty->Store.init
    let set = (x: input): t => x->toEither->Inner.set->storeToSum
    let show = (store: t) => store->storeToEither->Inner.show

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)->Dynamic.map(storeToSum)
    }

    type actionsInner<'out> = P.structure<A.actions<'out>, B.actions<'out>>
    let mapActionsInner: (actionsInner<'ch>, 'ch => 'b) => actionsInner<'b> = (ac, fn) =>
      ac->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions: (actions<'change>, 'change => 'b) => actions<'b> = (actions, fn) =>
      actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    type pack = Form.t<t, actions<unit>>
    type parted = S.t<Form.t<A.t, A.actions<unit>>, Form.t<B.t, B.actions<unit>>>
    let split: Form.t<t, actions<unit>> => parted = part => {
      Inner.splitInner(part.field->Store.inner->toEither, part.actions.inner->toTuple)->fromEither
    }
    
    let actionsFromVector: Inner.actions<()> => actions<()> = FieldVector.Actions.trimap(_, toEither, x=>x, fromTuple)
    let packFromEither = Form.bimap(_, storeToSum, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toEither), set->Dynamic.map(toEither), val)
      ->Dyn.map(Close.map(_, packFromEither))
    }
 
    let input = (store: t): input => store->storeToEither->Inner.input->fromEither
    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = store => store->storeToEither->Inner.printError
  }
}

module Sum3 = {
  module Tuple = Product2.Tuple
  module T = Product2.T
  type sum<'a, 'b, 'c> = Product3.PolyVariant.t<'a, 'b, 'c>

  module type Interface = {
    // A variant type that has values of our own choosing
    type t<'a, 'b, 'c>
    let toSum: t<'a, 'b, 'c> => sum<'a, 'b, 'c>
    let fromSum: sum<'a, 'b, 'c> => t<'a, 'b, 'c>
  }

  module Context = FieldEither.Context

  module type T = {
    include Field.T
    type parted
    type pack
    let split: pack => parted
  }

  // giving the Make functor this
  module type Make = (S: Interface, P: Product3.Generic, A: Field.T, B: Field.T, C: Field.T) =>
  (
    T
      with type input = S.t<A.input, B.input, C.input>
      and type inner = S.t<A.t, B.t, C.t>
      and type output = S.t<A.output, B.output, C.output>
      and type error = error
      and type t = Store.t<S.t<A.t, B.t, C.t>, S.t<A.output, B.output, C.output>, error>
      and type context = Context.t<
        S.t<A.input, B.input, C.input>,
        FieldVector.validateOut<S.t<A.output, B.output, C.output>>,
        P.structure<A.context, B.context, C.context>,
      >
      and type actions<'change> = FieldVector.Actions.t<
        S.t<A.input, B.input, C.input>,
        'change,
        P.structure<A.actions<'change>, B.actions<'change>, C.actions<'change>>,
      >
      and type pack = Form.t<
        Store.t<S.t<A.t, B.t, C.t>, S.t<A.output, B.output, C.output>, error>,
        FieldVector.Actions.t<
          S.t<A.input, B.input, C.input>,
          unit,
          P.structure<A.actions<unit>, B.actions<unit>, C.actions<unit>>,
        >,
      >
      and type parted = S.t<
        Form.t<A.t, A.actions<unit>>,
        Form.t<B.t, B.actions<unit>>,
        Form.t<C.t, C.actions<unit>>,
      >
  )

  //Sum needs Product for maintaining context
  module Make: Make = (S: Interface, P: Product3.Generic, A: Field.T, B: Field.T, C: Field.T) => {
    module T = Product3.T
    module Inner = FieldEither.Either3.Make(A, B, C)
    type either<'a, 'b, 'c> = Either.Nested.t3<'a, 'b, 'c>

    type input = S.t<A.input, B.input, C.input>
    type inner = S.t<A.t, B.t, C.t>
    type output = S.t<A.output, B.output, C.output>
    type error = [#Whole(string) | #Part]

    type t = Store.t<inner, output, error>

    type validate = FieldVector.validateOut<output>
    type contextInner = P.structure<A.context, B.context, C.context>
    type context = Context.t<input, validate, contextInner>

    // Context is the product equivalent of this sum, so we need toTuple in x->S.toSum->FieldProduct.Product1.PolyVariant.toEither
    let toTuple: P.structure<'a, 'b, 'c> => T.t<'a, 'b, 'c> = x =>
      P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b, 'c> => P.structure<'a, 'b, 'c> = x => x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b, 'c>): either<'a, 'b, 'c> =>
      s->S.toSum->Product3.PolyVariant.toEither
    let fromEither: either<'a, 'b, 'c> => S.t<'a, 'b, 'c> = x =>
      x->Product3.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither = Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, (v, out) => out->fromEither->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty: option<Inner.input> = context.empty->Option.map(toEither)
      let validate = context.validate->validateToEither
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toEither->Inner.showInput

    // prefer a context given empty value over const A
    let empty = (context: context) => context->contextToTuple->Inner.empty->fromEither
    let init = context => context->empty->Store.init
    let set = (x: input): t => x->toEither->Inner.set->storeToSum
    let show = (store: t) => store->storeToEither->Inner.show

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)->Dynamic.map(storeToSum)
    }

    type actionsInner<'out> = P.structure<A.actions<'out>, B.actions<'out>, C.actions<'out>>
    let mapActionsInner: (actionsInner<'ch>, 'ch => 'b) => actionsInner<'b> = (ac, fn) =>
      ac->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions: (actions<'change>, 'change => 'b) => actions<'b> = (actions, fn) =>
      actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    type pack = Form.t<t, actions<unit>>
    type parted = S.t<
      Form.t<A.t, A.actions<unit>>,
      Form.t<B.t, B.actions<unit>>,
      Form.t<C.t, C.actions<unit>>,
    >
    let split: Form.t<t, actions<unit>> => parted = part => {
      Inner.splitInner(part.field->Store.inner->toEither, part.actions.inner->toTuple)->fromEither
    }
    
    let actionsFromVector: Inner.actions<()> => actions<()> = FieldVector.Actions.trimap(_, toEither, x=>x, fromTuple)
    let packFromEither = Form.bimap(_, storeToSum, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toEither), set->Dynamic.map(toEither), val)
      ->Dyn.map(Close.map(_, packFromEither))
    }
 
    let input = (store: t): input => store->storeToEither->Inner.input->fromEither
    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = store => store->storeToEither->Inner.printError
  }
}

module Sum4 = {
  module Tuple = Product4.Tuple
  module T = Product4.T
  type sum<'a, 'b, 'c, 'd> = Product4.PolyVariant.t<'a, 'b, 'c, 'd>

  module type Interface = {
    // A variant type that has values of our own choosing
    type t<'a, 'b, 'c, 'd>
    let toSum: t<'a, 'b, 'c, 'd> => sum<'a, 'b, 'c, 'd>
    let fromSum: sum<'a, 'b, 'c, 'd> => t<'a, 'b, 'c, 'd>
  }

  module Context = FieldEither.Context

  module type T = {
    include Field.T
    type parted
    type pack
    let split: pack => parted
  }

  // giving the Make functor this
  module type Make = (
    S: Interface,
    P: Product4.Generic,
    A: Field.T,
    B: Field.T,
    C: Field.T,
    D: Field.T,
  ) =>
  (
    T
      with type input = S.t<A.input, B.input, C.input, D.input>
      and type inner = S.t<A.t, B.t, C.t, D.t>
      and type output = S.t<A.output, B.output, C.output, D.output>
      and type error = error
      and type t = Store.t<
        S.t<A.t, B.t, C.t, D.t>,
        S.t<A.output, B.output, C.output, D.output>,
        error,
      >
      and type context = Context.t<
        S.t<A.input, B.input, C.input, D.input>,
        FieldVector.validateOut<S.t<A.output, B.output, C.output, D.output>>,
        P.structure<A.context, B.context, C.context, D.context>,
      >
      and type actions<'change> = FieldVector.Actions.t<
        S.t<A.input, B.input, C.input, D.input>,
        'change,
        P.structure<A.actions<'change>, B.actions<'change>, C.actions<'change>, D.actions<'change>>,
      >
      and type pack = Form.t<
        Store.t<S.t<A.t, B.t, C.t, D.t>, S.t<A.output, B.output, C.output, D.output>, error>,
        FieldVector.Actions.t<
          S.t<A.input, B.input, C.input, D.input>,
          unit,
          P.structure<A.actions<unit>, B.actions<unit>, C.actions<unit>, D.actions<unit>>,
        >,
      >
      and type parted = S.t<
        Form.t<A.t, A.actions<unit>>,
        Form.t<B.t, B.actions<unit>>,
        Form.t<C.t, C.actions<unit>>,
        Form.t<D.t, D.actions<unit>>,
      >
  )

  //Sum needs Product for maintaining context
  module Make: Make = (
    S: Interface,
    P: Product4.Generic,
    A: Field.T,
    B: Field.T,
    C: Field.T,
    D: Field.T,
  ) => {
    module T = Product4.T
    module Inner = FieldEither.Either4.Make(A, B, C, D)
    type either<'a, 'b, 'c, 'd> = Either.Nested.t4<'a, 'b, 'c, 'd>

    type input = S.t<A.input, B.input, C.input, D.input>
    type inner = S.t<A.t, B.t, C.t, D.t>
    type output = S.t<A.output, B.output, C.output, D.output>
    type error = [#Whole(string) | #Part]

    type t = Store.t<inner, output, error>

    type validate = FieldVector.validateOut<output>
    type contextInner = P.structure<A.context, B.context, C.context, D.context>
    type context = Context.t<input, validate, contextInner>

    // Context is the product equivalent of this sum, so we need toTuple in x->S.toSum->FieldProduct.Product1.PolyVariant.toEither
    let toTuple: P.structure<'a, 'b, 'c, 'd> => T.t<'a, 'b, 'c, 'd> = x =>
      P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b, 'c, 'd> => P.structure<'a, 'b, 'c, 'd> = x =>
      x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b, 'c, 'd>): either<'a, 'b, 'c, 'd> =>
      s->S.toSum->Product4.PolyVariant.toEither
    let fromEither: either<'a, 'b, 'c, 'd> => S.t<'a, 'b, 'c, 'd> = x =>
      x->Product4.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither = Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, (v, out) => out->fromEither->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty: option<Inner.input> = context.empty->Option.map(toEither)
      let validate = context.validate->validateToEither
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toEither->Inner.showInput

    // prefer a context given empty value over const A
    let empty = (context: context) => context->contextToTuple->Inner.empty->fromEither
    let init = context => context->empty->Store.init
    let set = (x: input): t => x->toEither->Inner.set->storeToSum
    let show = (store: t) => store->storeToEither->Inner.show

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)->Dynamic.map(storeToSum)
    }

    type actionsInner<'out> = P.structure<
      A.actions<'out>,
      B.actions<'out>,
      C.actions<'out>,
      D.actions<'out>,
    >
    let mapActionsInner: (actionsInner<'ch>, 'ch => 'b) => actionsInner<'b> = (ac, fn) =>
      ac->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions: (actions<'change>, 'change => 'b) => actions<'b> = (actions, fn) =>
      actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    type pack = Form.t<t, actions<unit>>

    type parted = S.t<
      Form.t<A.t, A.actions<unit>>,
      Form.t<B.t, B.actions<unit>>,
      Form.t<C.t, C.actions<unit>>,
      Form.t<D.t, D.actions<unit>>,
    >
    let split: Form.t<t, actions<unit>> => parted = part => {
      Inner.splitInner(part.field->Store.inner->toEither, part.actions.inner->toTuple)->fromEither
    }

    let actionsFromVector: Inner.actions<()> => actions<()> = FieldVector.Actions.trimap(_, toEither, x=>x, fromTuple)
    let packFromEither = Form.bimap(_, storeToSum, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toEither), set->Dynamic.map(toEither), val)
      ->Dyn.map(Close.map(_, packFromEither))
    }
 

    let input = (store: t): input => store->storeToEither->Inner.input->fromEither
    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = store => store->storeToEither->Inner.printError
  }
}

module Sum5 = {
  module Tuple = Product5.Tuple
  module T = Product5.T
  type sum<'a, 'b, 'c, 'd, 'e> = Product5.PolyVariant.t<'a, 'b, 'c, 'd, 'e>

  module type Interface = {
    // A variant type that has values of our own choosing
    type t<'a, 'b, 'c, 'd, 'e>
    let toSum: t<'a, 'b, 'c, 'd, 'e> => sum<'a, 'b, 'c, 'd, 'e>
    let fromSum: sum<'a, 'b, 'c, 'd, 'e> => t<'a, 'b, 'c, 'd, 'e>
  }

  module Context = FieldEither.Context

  module type T = {
    include Field.T
    type parted
    type pack
    let split: pack => parted
  }

  // giving the Make functor this
  module type Make = (
    S: Interface,
    P: Product5.Generic,
    A: Field.T,
    B: Field.T,
    C: Field.T,
    D: Field.T,
    E: Field.T,
  ) =>
  (
    T
      with type input = S.t<A.input, B.input, C.input, D.input, E.input>
      and type inner = S.t<A.t, B.t, C.t, D.t, E.t>
      and type output = S.t<A.output, B.output, C.output, D.output, E.output>
      and type error = error
      and type t = Store.t<
        S.t<A.t, B.t, C.t, D.t, E.t>,
        S.t<A.output, B.output, C.output, D.output, E.output>,
        error,
      >
      and type context = Context.t<
        S.t<A.input, B.input, C.input, D.input, E.input>,
        FieldVector.validateOut<S.t<A.output, B.output, C.output, D.output, E.output>>,
        P.structure<A.context, B.context, C.context, D.context, E.context>,
      >
      and type actions<'change> = FieldVector.Actions.t<
        S.t<A.input, B.input, C.input, D.input, E.input>,
        'change,
        P.structure<
          A.actions<'change>,
          B.actions<'change>,
          C.actions<'change>,
          D.actions<'change>,
          E.actions<'change>,
        >,
      >
      and type pack = Form.t<
        Store.t<
          S.t<A.t, B.t, C.t, D.t, E.t>,
          S.t<A.output, B.output, C.output, D.output, E.output>,
          error,
        >,
        FieldVector.Actions.t<
          S.t<A.input, B.input, C.input, D.input, E.input>,
          unit,
          P.structure<
            A.actions<unit>,
            B.actions<unit>,
            C.actions<unit>,
            D.actions<unit>,
            E.actions<unit>,
          >,
        >,
      >
      and type parted = S.t<
        Form.t<A.t, A.actions<unit>>,
        Form.t<B.t, B.actions<unit>>,
        Form.t<C.t, C.actions<unit>>,
        Form.t<D.t, D.actions<unit>>,
        Form.t<E.t, E.actions<unit>>,
      >
  )

  //Sum needs Product for maintaining context
  module Make: Make = (
    S: Interface,
    P: Product5.Generic,
    A: Field.T,
    B: Field.T,
    C: Field.T,
    D: Field.T,
    E: Field.T,
  ) => {
    module T = Product5.T
    module Inner = FieldEither.Either5.Make(A, B, C, D, E)
    type either<'a, 'b, 'c, 'd, 'e> = Either.Nested.t5<'a, 'b, 'c, 'd, 'e>

    type input = S.t<A.input, B.input, C.input, D.input, E.input>
    type inner = S.t<A.t, B.t, C.t, D.t, E.t>
    type output = S.t<A.output, B.output, C.output, D.output, E.output>
    type error = [#Whole(string) | #Part]

    type t = Store.t<inner, output, error>

    type validate = FieldVector.validateOut<output>
    type contextInner = P.structure<A.context, B.context, C.context, D.context, E.context>
    type context = Context.t<input, validate, contextInner>

    // Context is the product equivalent of this sum, so we need toTuple in x->S.toSum->FieldProduct.Product1.PolyVariant.toEither
    let toTuple: P.structure<'a, 'b, 'c, 'd, 'e> => T.t<'a, 'b, 'c, 'd, 'e> = x =>
      P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b, 'c, 'd, 'e> => P.structure<'a, 'b, 'c, 'd, 'e> = x =>
      x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b, 'c, 'd, 'e>): either<'a, 'b, 'c, 'd, 'e> =>
      s->S.toSum->Product5.PolyVariant.toEither
    let fromEither: either<'a, 'b, 'c, 'd, 'e> => S.t<'a, 'b, 'c, 'd, 'e> = x =>
      x->Product5.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither = Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, (v, out) => out->fromEither->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty: option<Inner.input> = context.empty->Option.map(toEither)
      let validate = context.validate->validateToEither
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toEither->Inner.showInput

    // prefer a context given empty value over const A
    let empty = (context: context) => context->contextToTuple->Inner.empty->fromEither
    let init = context => context->empty->Store.init
    let set = (x: input): t => x->toEither->Inner.set->storeToSum
    let show = (store: t) => store->storeToEither->Inner.show

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)->Dynamic.map(storeToSum)
    }

    type actionsInner<'out> = P.structure<
      A.actions<'out>,
      B.actions<'out>,
      C.actions<'out>,
      D.actions<'out>,
      E.actions<'out>,
    >
    let mapActionsInner: (actionsInner<'ch>, 'ch => 'b) => actionsInner<'b> = (ac, fn) =>
      ac->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions: (actions<'change>, 'change => 'b) => actions<'b> = (actions, fn) =>
      actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    type pack = Form.t<t, actions<unit>>

    type parted = S.t<
      Form.t<A.t, A.actions<unit>>,
      Form.t<B.t, B.actions<unit>>,
      Form.t<C.t, C.actions<unit>>,
      Form.t<D.t, D.actions<unit>>,
      Form.t<E.t, E.actions<unit>>,
    >

    let split: Form.t<t, actions<unit>> => parted = part => {
      Inner.splitInner(part.field->Store.inner->toEither, part.actions.inner->toTuple)->fromEither
    }

    let actionsFromVector: Inner.actions<()> => actions<()> = FieldVector.Actions.trimap(_, toEither, x=>x, fromTuple)
    let packFromEither = Form.bimap(_, storeToSum, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toEither), set->Dynamic.map(toEither), val)
      ->Dyn.map(Close.map(_, packFromEither))
    }
 

    let input = (store: t): input => store->storeToEither->Inner.input->fromEither
    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = store => store->storeToEither->Inner.printError
  }
}

module Sum6 = {
  module Tuple = Product6.Tuple
  module T = Product6.T
  type sum<'a, 'b, 'c, 'd, 'e, 'f> = Product6.PolyVariant.t<'a, 'b, 'c, 'd, 'e, 'f>

  module type Interface = {
    // A variant type that has values of our own choosing
    type t<'a, 'b, 'c, 'd, 'e, 'f>
    let toSum: t<'a, 'b, 'c, 'd, 'e, 'f> => sum<'a, 'b, 'c, 'd, 'e, 'f>
    let fromSum: sum<'a, 'b, 'c, 'd, 'e, 'f> => t<'a, 'b, 'c, 'd, 'e, 'f>
  }

  module Context = FieldEither.Context

  module type T = {
    include Field.T
    type parted
    type pack
    let split: pack => parted
  }

  // giving the Make functor this
  module type Make = (
    S: Interface,
    P: Product6.Generic,
    A: Field.T,
    B: Field.T,
    C: Field.T,
    D: Field.T,
    E: Field.T,
    F: Field.T,
  ) =>
  (
    T
      with type input = S.t<A.input, B.input, C.input, D.input, E.input, F.input>
      and type inner = S.t<A.t, B.t, C.t, D.t, E.t, F.t>
      and type output = S.t<A.output, B.output, C.output, D.output, E.output, F.output>
      and type error = error
      and type t = Store.t<
        S.t<A.t, B.t, C.t, D.t, E.t, F.t>,
        S.t<A.output, B.output, C.output, D.output, E.output, F.output>,
        error,
      >
      and type context = Context.t<
        S.t<A.input, B.input, C.input, D.input, E.input, F.input>,
        FieldVector.validateOut<S.t<A.output, B.output, C.output, D.output, E.output, F.output>>,
        P.structure<A.context, B.context, C.context, D.context, E.context, F.context>,
      >
      and type actions<'change> = FieldVector.Actions.t<
        S.t<A.input, B.input, C.input, D.input, E.input, F.input>,
        'change,
        P.structure<
          A.actions<'change>,
          B.actions<'change>,
          C.actions<'change>,
          D.actions<'change>,
          E.actions<'change>,
          F.actions<'change>,
        >,
      >
      and type pack = Form.t<
        Store.t<
          S.t<A.t, B.t, C.t, D.t, E.t, F.t>,
          S.t<A.output, B.output, C.output, D.output, E.output, F.output>,
          error,
        >,
        FieldVector.Actions.t<
          S.t<A.input, B.input, C.input, D.input, E.input, F.input>,
          unit,
          P.structure<
            A.actions<unit>,
            B.actions<unit>,
            C.actions<unit>,
            D.actions<unit>,
            E.actions<unit>,
            F.actions<unit>,
          >,
        >,
      >
      and type parted = S.t<
        Form.t<A.t, A.actions<unit>>,
        Form.t<B.t, B.actions<unit>>,
        Form.t<C.t, C.actions<unit>>,
        Form.t<D.t, D.actions<unit>>,
        Form.t<E.t, E.actions<unit>>,
        Form.t<F.t, F.actions<unit>>,
      >
  )

  //Sum needs Product for maintaining context
  module Make: Make = (
    S: Interface,
    P: Product6.Generic,
    A: Field.T,
    B: Field.T,
    C: Field.T,
    D: Field.T,
    E: Field.T,
    F: Field.T,
  ) => {
    module T = Product6.T
    module Inner = FieldEither.Either6.Make(A, B, C, D, E, F)
    type either<'a, 'b, 'c, 'd, 'e, 'f> = Either.Nested.t6<'a, 'b, 'c, 'd, 'e, 'f>

    type input = S.t<A.input, B.input, C.input, D.input, E.input, F.input>
    type inner = S.t<A.t, B.t, C.t, D.t, E.t, F.t>
    type output = S.t<A.output, B.output, C.output, D.output, E.output, F.output>
    type error = [#Whole(string) | #Part]

    type t = Store.t<inner, output, error>

    type validate = FieldVector.validateOut<output>
    type contextInner = P.structure<
      A.context,
      B.context,
      C.context,
      D.context,
      E.context,
      F.context,
    >
    type context = Context.t<input, validate, contextInner>

    // Context is the product equivalent of this sum, so we need toTuple in x->S.toSum->FieldProduct.Product1.PolyVariant.toEither
    let toTuple: P.structure<'a, 'b, 'c, 'd, 'e, 'f> => T.t<'a, 'b, 'c, 'd, 'e, 'f> = x =>
      P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b, 'c, 'd, 'e, 'f> => P.structure<'a, 'b, 'c, 'd, 'e, 'f> = x =>
      x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b, 'c, 'd, 'e, 'f>): either<'a, 'b, 'c, 'd, 'e, 'f> =>
      s->S.toSum->Product6.PolyVariant.toEither
    let fromEither: either<'a, 'b, 'c, 'd, 'e, 'f> => S.t<'a, 'b, 'c, 'd, 'e, 'f> = x =>
      x->Product6.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither = Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, (v, out) => out->fromEither->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty: option<Inner.input> = context.empty->Option.map(toEither)
      let validate = context.validate->validateToEither
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toEither->Inner.showInput

    // prefer a context given empty value over const A
    let empty = (context: context) => context->contextToTuple->Inner.empty->fromEither
    let init = context => context->empty->Store.init
    let set = (x: input): t => x->toEither->Inner.set->storeToSum
    let show = (store: t) => store->storeToEither->Inner.show

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)->Dynamic.map(storeToSum)
    }

    type actionsInner<'out> = P.structure<
      A.actions<'out>,
      B.actions<'out>,
      C.actions<'out>,
      D.actions<'out>,
      E.actions<'out>,
      F.actions<'out>,
    >
    let mapActionsInner: (actionsInner<'ch>, 'ch => 'b) => actionsInner<'b> = (ac, fn) =>
      ac->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions: (actions<'change>, 'change => 'b) => actions<'b> = (actions, fn) =>
      actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    type pack = Form.t<t, actions<unit>>

    type parted = S.t<
      Form.t<A.t, A.actions<unit>>,
      Form.t<B.t, B.actions<unit>>,
      Form.t<C.t, C.actions<unit>>,
      Form.t<D.t, D.actions<unit>>,
      Form.t<E.t, E.actions<unit>>,
      Form.t<F.t, F.actions<unit>>,
    >

    let split: Form.t<t, actions<unit>> => parted = part => {
      Inner.splitInner(part.field->Store.inner->toEither, part.actions.inner->toTuple)->fromEither
    }

    let actionsFromVector: Inner.actions<()> => actions<()> = FieldVector.Actions.trimap(_, toEither, x=>x, fromTuple)
    let packFromEither = Form.bimap(_, storeToSum, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toEither), set->Dynamic.map(toEither), val)
      ->Dyn.map(Close.map(_, packFromEither))
    }
 
    let input = (store: t): input => store->storeToEither->Inner.input->fromEither
    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = store => store->storeToEither->Inner.printError
  }
}
