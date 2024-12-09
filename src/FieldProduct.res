@@ocamldoc("Extending FieldVector, A Field that composes multiple children, giving each child a name, and producing a record type as its output")

module Tuple = Tuple.Nested

type error = [#Whole(string) | #Part]
type resultValidate = Promise.t<Result.t<unit, string>>
type validateOut<'out> = 'out => resultValidate

module Context = {
  type t<'e, 'v, 'i> = {
    empty?: 'e,
    validate?: 'v,
    inner: 'i,
    validateImmediate?: bool,
  }

  // Cant deriving accessors with optional fields?
  let empty = t => t.empty
  let validate = t => t.validate
  let inner = t => t.inner
}

module type T = {
  include Field.T
  type contextInner
  type parted
  type pack
  let split: pack => parted
}


module Product1 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple1

  // No such thing as a 1-tuple in rescript so slightly diffrent than the rest
  module type Generic = {
    type structure<'a>

    let fromTuple: (('a)) => structure<'a>
    let order: (structure<'a> => 'a)
  }

  module PolyVariant = {
    type t<'a> = [#A('a)]
    let toEither = (ch: t<'a>) => {
      switch ch {
      | #A(ch) => Either.Left(ch)
      }
    }
    let fromEither = (ch: Either.Nested.t1<'a>): t<'a> => {
      switch ch {
      | Either.Left(ch) => #A(ch)
      | Either.Right(_) => {
          Console.log2("fromEither", ch)
          failwith("impossible")
        }
      }
    }
  }

  // giving the Make functor this
  module type Make = (Gen: Generic, A: Field.T)
   => T
    with type input = Gen.structure<A.input>
    and type inner = Gen.structure<A.t>
    and type output = Gen.structure<A.output>
    and type error = error
    and type t = Store.t<Gen.structure<A.t>, Gen.structure<A.output>, error>
    and type contextInner = Gen.structure<A.context>
    and type context = Context.t<Gen.structure<A.input>, validateOut<Gen.structure<A.output>>, Gen.structure<A.context>>
    and type actions<'change> = FieldVector.Actions.t<Gen.structure<A.input>, 'change, Gen.structure<A.actions<'change>>>
    and type pack = Form.t<
      Store.t<Gen.structure<A.t>, Gen.structure<A.output>, error>,
      FieldVector.Actions.t<
        Gen.structure<A.input>,
        (),
        Gen.structure<A.actions<()>>
      >
    >
    and type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
      >


  module Make: Make = (Gen: Generic, A: Field.T) => {
    module A = A
    module Inner = FieldVector.Vector1.Make(A)
    type input = Gen.structure<A.input>
    type inner = Gen.structure<A.t>
    type output = Gen.structure<A.output>
    type error = error
    type t = Store.t<inner, output, error>
    
    type validate = validateOut<output>
    type contextInner = Gen.structure<A.context>
    type context = Context.t<input, validate, contextInner>

    let toTuple: Gen.structure<'a> => T.t<'a> = x => Gen.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a> => Gen.structure<'a> = x => x->T.decode->Gen.fromTuple

    let storeToStructure = Store.bimap(_, fromTuple, fromTuple)
    let storeToTuple = Store.bimap(_, toTuple, toTuple)

    let validateToTuple = Option.map(_, v => out => out->fromTuple->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty: option<Inner.input> = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner, validateImmediate: ?context.validateImmediate}
    }

    let showInput = (x: input) => x->toTuple->Inner.showInput

    let set = (x: input): t => x->toTuple->Inner.set->storeToStructure
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Inner.emptyInner->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Inner.printError

    let show = (store: t): string => {
      `Product1{
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Inner.showInner->Array.joinWith(",\n")}
        }
      }`
    }

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => 
      Inner.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
    >
    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions, fn) => actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))
  
    type pack = Form.t<t, actions<()>>
    type parted = Gen.structure<Form.t<A.t, A.actions<()>>>

    let split = (pack: pack): parted => {
      Inner.splitInner(
        pack.field->Store.inner->toTuple,
        pack.actions.inner->toTuple,
      )
      ->fromTuple
    }

    let actionsFromVector = FieldVector.Actions.trimap(_, toTuple, x=>x, fromTuple)
    let packFromVector = Form.bimap(_, storeToStructure, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toTuple), set->Dynamic.map(toTuple), val)
      ->Dyn.map(Close.map(_, packFromVector))
    }

    let input = (store: t) => store->storeToTuple->Inner.input->fromTuple
  }
}

module Product2 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple2

  module type Generic = {
    type structure<'a, 'b>

    let fromTuple: (('a, 'b)) => structure<'a, 'b>
    let order: (structure<'a, 'b> => 'a, structure<'a, 'b> => 'b)
  }

  module PolyVariant = {
    //Sums are reversed so we can keep the polyvariant lined up #A->a, etc...
    type tail<'a> = Product1.PolyVariant.t<'a>
    type t<'b, 'a> = [#B('b) | tail<'a> ]
    let toEither = (ch: t<'b, 'a>): Either.Nested.t2<'b, 'a> => {
      switch ch {
      | #B(ch) => Either.Left(ch)
      | #...tail as x => Either.Right(Product1.PolyVariant.toEither(x))
      }
    }
    let fromEither = (ch): t<'b, 'a> => {
      switch ch {
      | Either.Left(ch) => #B(ch)
      | Either.Right(ch) => Product1.PolyVariant.fromEither(ch) :> t<'b, 'a>
      }
    }
  }

  // giving the Make functor this
  module type Make = (Gen: Generic, A: Field.T, B: Field.T)
   => T
    with type input = Gen.structure<A.input, B.input>
    and type inner = Gen.structure<A.t, B.t>
    and type output = Gen.structure<A.output, B.output>
    and type error = error
    and type t = Store.t<Gen.structure<A.t, B.t>, Gen.structure<A.output, B.output>, error>
    and type contextInner = Gen.structure<A.context, B.context>
    and type context = Context.t<Gen.structure<A.input, B.input>, validateOut<Gen.structure<A.output, B.output>>, Gen.structure<A.context, B.context>>
    and type actions<'change> = FieldVector.Actions.t<Gen.structure<A.input, B.input>, 'change, Gen.structure<A.actions<'change>, B.actions<'change>>>
    and type pack = Form.t<
      Store.t<Gen.structure<A.t, B.t>, Gen.structure<A.output, B.output>, error>,
      FieldVector.Actions.t<
        Gen.structure<A.input, B.input>,
        (),
        Gen.structure<A.actions<()>, B.actions<()>>
      >
    >
    and type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
      >


  module Make: Make = (Gen: Generic, A: Field.T, B: Field.T) => {
    module A = A
    module B = B
    module Inner = FieldVector.Vector2.Make(A, B)

    type input = Gen.structure<A.input, B.input>
    type inner = Gen.structure<A.t, B.t>
    type output = Gen.structure<A.output, B.output>
    type error = error
    type t = Store.t<inner, output, error>
    
    type validate = validateOut<output>
    type contextInner = Gen.structure<A.context, B.context>
    type context = Context.t<input, validate, contextInner>

    // These are reversed to allow Generic to be legible and Tuple to be packed with common elements more interior to the tuple
    let toTuple: Gen.structure<'a, 'b> => T.t<'b, 'a> = x => Gen.order->T.encode->T.reverse->T.napply(T.return(x))
    let fromTuple: T.t<'b, 'a> => Gen.structure<'a,'b> = x => x->T.reverse->T.decode->Gen.fromTuple

    let storeToStructure = Store.bimap(_, fromTuple, fromTuple)
    let storeToTuple = Store.bimap(_, toTuple, toTuple)

    let validateToTuple = Option.map(_, v => out => out->fromTuple->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty: option<Inner.input> = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner, validateImmediate: ?context.validateImmediate}
    }

    let showInput = (x: input) => x->toTuple->Inner.showInput

    let set = (x: input): t => x->toTuple->Inner.set->storeToStructure
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Inner.emptyInner->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Inner.printError

    let show = (store: t): string => {
      `Product2{
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Inner.showInner->Array.joinWith(",\n")}
        }
      }`
    }

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => 
      Inner.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>
    >
    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions: actions<'ch> , fn: 'ch => 'b): actions<'b> => actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))
    
    type pack = Form.t<t, actions<()>>
    type parted = Gen.structure<
      Form.t<A.t, A.actions<()>>,
      Form.t<B.t, B.actions<()>>
    >

    let split = (pack: pack)
      : parted => {
      Inner.splitInner(
        pack.field->Store.inner->toTuple,
        pack.actions.inner->toTuple,
      )
      ->fromTuple
    }
  
    let actionsFromVector = FieldVector.Actions.trimap(_, toTuple, x=>x, fromTuple)
    let packFromVector = Form.bimap(_, storeToStructure, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toTuple), set->Dynamic.map(toTuple), val)
      ->Dyn.map(Close.map(_, packFromVector))
    }
 
    let input = (store: t) => store->storeToTuple->Inner.input->fromTuple
  }
}

module Product3 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple3

  module type Generic = {
    type structure<'a, 'b, 'c>

    let order: (structure<'a, 'b, 'c> => 'a, structure<'a, 'b, 'c> => 'b, structure<'a, 'b, 'c> => 'c)
    let fromTuple: (('a, 'b, 'c)) => structure<'a, 'b, 'c>
  }

  module PolyVariant = {
    //Sums are reversed so we can keep the polyvariant lined up #A->a, etc...
    type tail<'b, 'a> = Product2.PolyVariant.t<'b, 'a>
    type t<'c, 'b, 'a> = [#C('c) | tail<'b, 'a>]
    let toEither = (ch: t<'c, 'b, 'a>) => {
      switch ch {
      | #C(ch) => Either.Left(ch)
      | #...tail as x => Either.Right(Product2.PolyVariant.toEither(x))
      }
    }
    let fromEither = (ch): t<'c, 'b, 'a> => {
      switch ch {
      | Either.Left(ch) => #C(ch)
      | Either.Right(ch) => Product2.PolyVariant.fromEither(ch) :> t<'c, 'b, 'a>
      }
    }
  }

 // giving the Make functor this
  module type Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T)
   => T
    with type input = Gen.structure<A.input, B.input, C.input>
    and type inner = Gen.structure<A.t, B.t, C.t>
    and type output = Gen.structure<A.output, B.output, C.output>
    and type error = error
    and type t = Store.t<Gen.structure<A.t, B.t, C.t>, Gen.structure<A.output, B.output, C.output>, error>
    and type contextInner = Gen.structure<A.context, B.context, C.context>
    and type context = Context.t<Gen.structure<A.input, B.input, C.input>, validateOut<Gen.structure<A.output, B.output, C.output>>, Gen.structure<A.context, B.context, C.context>>
    and type actions<'change> = FieldVector.Actions.t<Gen.structure<A.input, B.input, C.input>, 'change, Gen.structure<A.actions<'change>, B.actions<'change>, C.actions<'change>>>
    and type pack = Form.t<
      Store.t<Gen.structure<A.t, B.t, C.t>, Gen.structure<A.output, B.output, C.output>, error>,
      FieldVector.Actions.t<
        Gen.structure<A.input, B.input, C.input>,
        (),
        Gen.structure<A.actions<()>, B.actions<()>, C.actions<()>>
      >
    >
    and type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>
      >

  module Make : Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T) => {
    module Inner = FieldVector.Vector3.Make(A, B, C)
    type input = Gen.structure<A.input, B.input, C.input>
    type inner = Gen.structure<A.t, B.t, C.t>
    type output = Gen.structure<A.output, B.output, C.output>
    type error = error
    type t = Store.t<inner, output, error>

    type validate = validateOut<output>
    type contextInner = Gen.structure<A.context, B.context, C.context>
    type context = Context.t<input, validate, contextInner>
    
    // These are reversed to allow Generic to be legible and Tuple to be packed with A as the inner-most value
    let toTuple: Gen.structure<'a, 'b, 'c> => T.t<'c, 'b, 'a> = x => Gen.order->T.encode->T.reverse->T.napply(T.return(x))
    let fromTuple: T.t<'c, 'b, 'a> => Gen.structure<'a,'b,'c> = x => x->T.reverse->T.decode->Gen.fromTuple

    let storeToStructure = Store.bimap(_, fromTuple, fromTuple)
    let storeToTuple = Store.bimap(_, toTuple, toTuple)
    let validateToTuple  = Option.map(_, (v, out) => out->fromTuple->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner, validateImmediate: ?context.validateImmediate}
    }

    let showInput = (x: input) => x->toTuple->Inner.showInput

    let set = (x: input): t => x->toTuple->Inner.set->storeToStructure
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Inner.emptyInner->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => 
      Inner.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
    >
    
    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions: actions<'ch>, fn: 'ch => 'b) => actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))
    
    type pack = Form.t<t, actions<()>>
    type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>
      >
    let split = (pack: pack) : parted => {
      Inner.splitInner(
        pack.field->Store.inner->toTuple,
        pack.actions.inner->toTuple,
      )
      ->fromTuple
    }
  
    let actionsFromVector = FieldVector.Actions.trimap(_, toTuple, x=>x, fromTuple)
    let packFromVector = Form.bimap(_, storeToStructure, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
     Inner.makeDyn(context->contextToTuple, initial->Option.map(toTuple), set->Dynamic.map(toTuple), val)
      ->Dyn.map(Close.map(_, packFromVector))
    }
 
    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Inner.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Inner.printError

    let show = (store: t): string => {
      `Product3{
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Inner.showInner->Array.joinWith(",\n")}
        }}`
    }
  }
}

module Product4 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple4

  module type Generic = {
    type structure<'a, 'b, 'c, 'd>

    let order: (structure<'a, 'b, 'c, 'd> => 'a, structure<'a, 'b, 'c, 'd> => 'b, structure<'a, 'b, 'c, 'd> => 'c, structure<'a, 'b, 'c, 'd> => 'd)
    let fromTuple: (('a, 'b, 'c, 'd)) => structure<'a, 'b, 'c, 'd>
  }

  module PolyVariant = {  
    //Sums are reversed so we can keep the polyvariant lined up #A->a, etc...
    type tail<'c, 'b, 'a> = Product3.PolyVariant.t<'c, 'b, 'a>
    type t<'d, 'c, 'b, 'a> = [#D('d) | tail<'c, 'b, 'a> ]
    let toEither = (ch: t<'d, 'c, 'b, 'a>) => {
      switch ch {
      | #D(ch) => Either.Left(ch)
      | #...tail as x => Either.Right(Product3.PolyVariant.toEither(x))
      }
    }
    let fromEither = (ch) => {
      switch ch {
      | Either.Left(ch) => #D(ch)
      | Either.Right(ch) => Product3.PolyVariant.fromEither(ch) :> t<'d, 'c, 'b, 'a>
      }
    }
  }
  module type Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T)
   => T
    with type input = Gen.structure<A.input, B.input, C.input, D.input>
    and type inner = Gen.structure<A.t, B.t, C.t, D.t>
    and type output = Gen.structure<A.output, B.output, C.output, D.output>
    and type error = error
    and type t = Store.t<
      Gen.structure<A.t, B.t, C.t, D.t>,
      Gen.structure<A.output, B.output, C.output, D.output>,
      error
    >
    and type contextInner = Gen.structure<A.context, B.context, C.context, D.context>
    and type context = Context.t<
      Gen.structure<A.input, B.input, C.input, D.input>,
      validateOut<Gen.structure<A.output, B.output, C.output, D.output>>,
      Gen.structure<A.context, B.context, C.context, D.context>
    >
    and type actions<'change> = FieldVector.Actions.t<
      Gen.structure<A.input, B.input, C.input, D.input>,
      'change,
      Gen.structure<
        A.actions<'change>,
        B.actions<'change>,
        C.actions<'change>,
        D.actions<'change>,
      >
    >
    and type pack = Form.t<
      Store.t<
        Gen.structure<A.t, B.t, C.t, D.t>,
        Gen.structure<A.output, B.output, C.output, D.output>,
        error
      >,
      FieldVector.Actions.t<
        Gen.structure<A.input, B.input, C.input, D.input>,
        (),
        Gen.structure<
          A.actions<()>,
          B.actions<()>,
          C.actions<()>,
          D.actions<()>,
        >
      >
    >
    and type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>,
      >


  module Make: Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T) => {
    module Inner = FieldVector.Vector4.Make(A, B, C, D)
    type input = Gen.structure<A.input, B.input, C.input, D.input>
    type inner = Gen.structure<A.t, B.t, C.t, D.t>
    type output = Gen.structure<A.output, B.output, C.output, D.output>
    type error = error
    type t = Store.t<inner, output, error>

    type validate = validateOut<output>
    type contextInner = Gen.structure<A.context, B.context, C.context, D.context>
    type context = Context.t<input, validate, contextInner>

    // These are reversed to allow Generic to be legible and Tuple to be packed with A as the inner-most value
    let toTuple: Gen.structure<'a, 'b, 'c, 'd> => T.t<'d, 'c, 'b, 'a> = x => Gen.order->T.encode->T.reverse->T.napply(T.return(x))
    let fromTuple: T.t<'d, 'c, 'b, 'a> => Gen.structure<'a,'b,'c, 'd> = x => x->T.reverse->T.decode->Gen.fromTuple

    let storeToStructure = Store.bimap(_, fromTuple, fromTuple)
    let storeToTuple = Store.bimap(_, toTuple, toTuple)
    let validateToTuple = Option.map(_, v => out => out->fromTuple->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner, validateImmediate: ?context.validateImmediate}
    }

    let showInput = (x: input) => x->toTuple->Inner.showInput

    let set = (x: input) => x->toTuple->Inner.set->storeToStructure
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Inner.emptyInner->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => 
      Inner.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
      D.actions<'change>,
    >
    
    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions: actions<'ch>, fn: 'ch => 'b) => actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))
    
    type pack = Form.t<t, actions<()>>
    type parted = Gen.structure<
      Form.t<A.t, A.actions<()>>,
      Form.t<B.t, B.actions<()>>,
      Form.t<C.t, C.actions<()>>,
      Form.t<D.t, D.actions<()>>
    >

    let split = (pack: pack): parted => {
      Inner.splitInner(
        pack.field->Store.inner->toTuple,
        pack.actions.inner->toTuple,
      )
      ->fromTuple
    }

    let actionsFromVector = FieldVector.Actions.trimap(_, toTuple, x=>x, fromTuple)
    let packFromVector = Form.bimap(_, storeToStructure, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      let {first, init, dyn} = Inner.makeDyn(context->contextToTuple, initial->Option.map(toTuple), set->Dynamic.map(toTuple), val)
      ->Dyn.map(Close.map(_, packFromVector))

      let init = init
      // ->Dynamic.log("prod4")
      {first, init, dyn }
    }
 
    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Inner.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = (store: t) => store->storeToTuple->Inner.printError

    let show = (store: t): string => {
      `Product4{
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Inner.showInner->Array.joinWith(",\n")}
        }
      }`
    }
  }
}

module Product5 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple5

  module type Generic = {
    type structure<'a, 'b, 'c, 'd, 'e>
    let order: (structure<'a, 'b, 'c, 'd, 'e> => 'a, structure<'a, 'b, 'c, 'd, 'e> => 'b, structure<'a, 'b, 'c, 'd, 'e> => 'c, structure<'a, 'b, 'c, 'd, 'e> => 'd, structure<'a, 'b, 'c, 'd, 'e> => 'e)
    let fromTuple: (('a, 'b, 'c, 'd, 'e)) => structure<'a, 'b, 'c, 'd, 'e>
  }

  module PolyVariant = {
    //Sums are reversed so we can keep the polyvariant lined up #A->a, etc...
    type tail<'d, 'c, 'b, 'a> = Product4.PolyVariant.t<'d, 'c, 'b, 'a>
    type t<'e, 'd, 'c, 'b, 'a> = [#E('e) | tail<'d, 'c, 'b, 'a>]
    let toEither = (ch: t<'e, 'd, 'c, 'b, 'a>) => {
      switch ch {
      | #E(ch) => Either.Left(ch)
      | #...tail as x => Either.Right(Product4.PolyVariant.toEither(x))
      }
    }
    let fromEither = (ch) => {
      switch ch {
      | Either.Left(ch) => #E(ch)
      | Either.Right(ch) => Product4.PolyVariant.fromEither(ch) :> t<'e, 'd, 'c, 'b, 'a>
      }
    }
  }

  module type Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T)
   => T
    with type input = Gen.structure<A.input, B.input, C.input, D.input, E.input>
    and type inner = Gen.structure<A.t, B.t, C.t, D.t, E.t>
    and type output = Gen.structure<A.output, B.output, C.output, D.output, E.output>
    and type error = error
    and type t = Store.t<
      Gen.structure<A.t, B.t, C.t, D.t, E.t>,
      Gen.structure<A.output, B.output, C.output, D.output, E.output>,
      error
    >
    and type contextInner = Gen.structure<A.context, B.context, C.context, D.context, E.context>
    and type context = Context.t<
      Gen.structure<A.input, B.input, C.input, D.input, E.input>,
      validateOut<Gen.structure<A.output, B.output, C.output, D.output, E.output>>,
      Gen.structure<A.context, B.context, C.context, D.context, E.context>
    >
    and type actions<'change> = FieldVector.Actions.t<
      Gen.structure<A.input, B.input, C.input, D.input, E.input>,
      'change,
      Gen.structure<
        A.actions<'change>,
        B.actions<'change>,
        C.actions<'change>,
        D.actions<'change>,
        E.actions<'change>,
      >
    >
    and type pack = Form.t<
      Store.t<
        Gen.structure<A.t, B.t, C.t, D.t, E.t>,
        Gen.structure<A.output, B.output, C.output, D.output, E.output>,
        error
      >,
      FieldVector.Actions.t<
        Gen.structure<A.input, B.input, C.input, D.input, E.input>,
        (),
        Gen.structure<
          A.actions<()>,
          B.actions<()>,
          C.actions<()>,
          D.actions<()>,
          E.actions<()>,
        >
      >
    >
    and type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>,
        Form.t<E.t, E.actions<()>>,
      >

  module Make: Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T) => {
    module Inner = FieldVector.Vector5.Make(A, B, C, D, E)
    type input = Gen.structure<A.input, B.input, C.input, D.input, E.input>
    type inner = Gen.structure<A.t, B.t, C.t, D.t, E.t>
    type output = Gen.structure<A.output, B.output, C.output, D.output, E.output>
    type error = error
    type t = Store.t<inner, output, error>

    type validate = validateOut<output>
    type contextInner = Gen.structure<A.context, B.context, C.context, D.context, E.context>
    type context = Context.t<input, validate, contextInner>

    // These are reversed to allow Generic to be legible and Tuple to be packed with A as the inner-most value
    let toTuple: Gen.structure<'a, 'b, 'c, 'd, 'e> => T.t<'e, 'd, 'c, 'b, 'a> = x => Gen.order->T.encode->T.reverse->T.napply(T.return(x))
    let fromTuple: T.t<'e, 'd, 'c, 'b, 'a> => Gen.structure<'a,'b,'c, 'd, 'e> = x => x->T.reverse->T.decode->Gen.fromTuple

    let storeToStructure = Store.bimap(_, fromTuple, fromTuple)
    let storeToTuple = Store.bimap(_, toTuple, toTuple)
    let validateToTuple = Option.map(_, v => out => out->fromTuple->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner, validateImmediate: ?context.validateImmediate}
    }

    let showInput = (x: input) => x->toTuple->Inner.showInput
    let set = (x: input): t => x->toTuple->Inner.set->storeToStructure
    
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Inner.emptyInner->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => 
      Inner.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
      D.actions<'change>,
      E.actions<'change>
    >

    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions: actions<'ch>, fn: 'ch => 'b) => actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))
    
    type pack = Form.t<t, actions<()>>
    type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>,
        Form.t<E.t, E.actions<()>>
      >

    let split = (pack: pack)
      : parted => {
      Inner.splitInner(
        pack.field->Store.inner->toTuple,
        pack.actions.inner->toTuple,
      )
      ->fromTuple
    }

    let actionsFromVector = FieldVector.Actions.trimap(_, toTuple, x=>x, fromTuple)
    let packFromVector = Form.bimap(_, storeToStructure, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toTuple), set->Dynamic.map(toTuple), val)
      ->Dyn.map(Close.map(_, packFromVector))
    }
 
    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Inner.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Inner.printError

    let show = (store: t): string => {
      `Product5{
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Inner.showInner->Array.joinWith(",\n")}
        }
      }`
    }
  }
}

module Product6 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple6

  module type Generic = {
    type structure<'a, 'b, 'c, 'd, 'e, 'f>
    let order: (structure<'a, 'b, 'c, 'd, 'e, 'f> => 'a, structure<'a, 'b, 'c, 'd, 'e, 'f> => 'b, structure<'a, 'b, 'c, 'd, 'e, 'f> => 'c, structure<'a, 'b, 'c, 'd, 'e, 'f> => 'd, structure<'a, 'b, 'c, 'd, 'e, 'f> => 'e, structure<'a, 'b, 'c, 'd, 'e, 'f> => 'f)
    let fromTuple: (('a, 'b, 'c, 'd, 'e, 'f)) => structure<'a, 'b, 'c, 'd, 'e, 'f>
  }

  module PolyVariant = {
    //Sums are reversed so we can keep the polyvariant lined up #A->a, etc...
    type tail<'e, 'd, 'c, 'b, 'a> = Product5.PolyVariant.t<'e, 'd, 'c, 'b, 'a>
    type t<'f, 'e, 'd, 'c, 'b, 'a> = [#F('f) | tail<'e, 'd, 'c, 'b, 'a>] 
    let toEither = (ch: t<'f, 'e, 'd, 'c, 'b, 'a>) => {
      switch ch {
      | #F(ch) => Either.Left(ch)
      | #...tail as x => Either.Right(Product5.PolyVariant.toEither(x))
      }
    }
    let fromEither = (ch) => {
      switch ch {
      | Either.Left(ch) => #F(ch)
      | Either.Right(ch) => Product5.PolyVariant.fromEither(ch) :> t<'f, 'e, 'd, 'c, 'b, 'a>
      }
    }
  }

  module type Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T)
   => T
    with type input = Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input>
    and type inner = Gen.structure<A.t, B.t, C.t, D.t, E.t, F.t>
    and type output = Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output>
    and type error = error
    and type t = Store.t<
      Gen.structure<A.t, B.t, C.t, D.t, E.t, F.t>,
      Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output>,
      error
    >
    and type contextInner = Gen.structure<A.context, B.context, C.context, D.context, E.context, F.context>
    and type context = Context.t<
      Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input>,
      validateOut<Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output>>,
      Gen.structure<A.context, B.context, C.context, D.context, E.context, F.context>
    >
    and type actions<'change> = FieldVector.Actions.t<
      Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input>,
      'change,
      Gen.structure<
        A.actions<'change>,
        B.actions<'change>,
        C.actions<'change>,
        D.actions<'change>,
        E.actions<'change>,
        F.actions<'change>,
      >
    >
    and type pack = Form.t<
      Store.t<
        Gen.structure<A.t, B.t, C.t, D.t, E.t, F.t>,
        Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output>,
        error
      >,
      FieldVector.Actions.t<
        Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input>,
        (),
        Gen.structure<
          A.actions<()>,
          B.actions<()>,
          C.actions<()>,
          D.actions<()>,
          E.actions<()>,
          F.actions<()>,
        >
      >
    >
    and type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>,
        Form.t<E.t, E.actions<()>>,
        Form.t<F.t, F.actions<()>>,
      >


  module Make: Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T) => {
    module Inner = FieldVector.Vector6.Make(A, B, C, D, E, F)
    type input = Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input>
    type inner = Gen.structure<A.t, B.t, C.t, D.t, E.t, F.t>
    type output = Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output>
    type error = error
    type t = Store.t<inner, output, error>

    type validate = validateOut<output>
    type contextInner = Gen.structure<A.context, B.context, C.context, D.context, E.context, F.context>
    type context = Context.t<input, validate, contextInner>

    // These are reversed to allow Generic to be legible and Tuple to be packed with A as the inner-most value
    let toTuple: Gen.structure<'a, 'b, 'c, 'd, 'e, 'f> => T.t<'f, 'e, 'd, 'c, 'b, 'a> = x => Gen.order->T.encode->T.reverse->T.napply(T.return(x))
    let fromTuple: T.t<'f, 'e, 'd, 'c, 'b, 'a> => Gen.structure<'a,'b,'c, 'd, 'e, 'f> = x => x->T.reverse->T.decode->Gen.fromTuple

    let storeToStructure = Store.bimap(_, fromTuple, fromTuple)
    let storeToTuple = Store.bimap(_, toTuple, toTuple)
    let validateToTuple = Option.map(_, v => out => out->fromTuple->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner, validateImmediate: ?context.validateImmediate}
    }

    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Inner.emptyInner->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let set = (x: input): t => x->toTuple->Inner.set->storeToStructure
    let showInput = (x: input) => x->toTuple->Inner.showInput

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => 
      Inner.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
      D.actions<'change>,
      E.actions<'change>,
      F.actions<'change>,
    >

    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions: actions<'ch>, fn: 'ch => 'b) => actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))
    
    type pack = Form.t<t, actions<()>>
    type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>,
        Form.t<E.t, E.actions<()>>,
        Form.t<F.t, F.actions<()>>
      >

    let split = (pack: pack): parted => {
      Inner.splitInner(
        pack.field->Store.inner->toTuple,
        pack.actions.inner->toTuple,
      )
      ->fromTuple
    }

    let actionsFromVector = FieldVector.Actions.trimap(_, toTuple, x=>x, fromTuple)
    let packFromVector = Form.bimap(_, storeToStructure, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toTuple), set->Dynamic.map(toTuple), val)
      ->Dyn.map(Close.map(_, packFromVector))
    }
 
    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Inner.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Inner.printError

    let show = (store: t): string => {
      `Product6{
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Inner.showInner->Array.joinWith(",\n")}
        }
      }`
    }
  }
}

module Product7 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple7

  module type Generic = {
    type structure<'a, 'b, 'c, 'd, 'e, 'f, 'g>
    let order: (
      structure<'a, 'b, 'c, 'd, 'e, 'f, 'g> => 'a,
      structure<'a, 'b, 'c, 'd, 'e, 'f, 'g> => 'b,
      structure<'a, 'b, 'c, 'd, 'e, 'f, 'g> => 'c,
      structure<'a, 'b, 'c, 'd, 'e, 'f, 'g> => 'd,
      structure<'a, 'b, 'c, 'd, 'e, 'f, 'g> => 'e,
      structure<'a, 'b, 'c, 'd, 'e, 'f, 'g> => 'f,
      structure<'a, 'b, 'c, 'd, 'e, 'f, 'g> => 'g
    )
    let fromTuple: (('a, 'b, 'c, 'd, 'e, 'f, 'g)) => structure<'a, 'b, 'c, 'd, 'e, 'f, 'g>
  }

  module PolyVariant = {
    //Sums are reversed so we can keep the polyvariant lined up #A->a, etc...
    type tail<'f, 'e, 'd, 'c, 'b, 'a> = Product6.PolyVariant.t<'f, 'e, 'd, 'c, 'b, 'a>
    type t<'g, 'f, 'e, 'd, 'c, 'b, 'a> = [#G('g) | tail<'f, 'e, 'd, 'c, 'b, 'a>]
    let toEither = (ch: t<'g, 'f, 'e, 'd, 'c, 'b, 'a>) => {
      switch ch {
      | #G(ch) => Either.Left(ch)
      | #...tail as x => Either.Right(Product6.PolyVariant.toEither(x))
      }
    }
    let fromEither = (ch) => {
      switch ch {
      | Either.Left(ch) => #G(ch)
      | Either.Right(ch) => Product6.PolyVariant.fromEither(ch) :> t<'g, 'f, 'e, 'd, 'c, 'b, 'a>
      }
    }
  }

  module type Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T, G: Field.T)
   => T
    with type input = Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input, G.input>
    and type inner = Gen.structure<A.t, B.t, C.t, D.t, E.t, F.t, G.t>
    and type output = Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output, G.output>
    and type error = error
    and type t = Store.t<
      Gen.structure<A.t, B.t, C.t, D.t, E.t, F.t, G.t>,
      Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output, G.output>,
      error
    >
    and type contextInner = Gen.structure<A.context, B.context, C.context, D.context, E.context, F.context, G.context>
    and type context = Context.t<
      Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input, G.input>,
      validateOut<Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output, G.output>>,
      Gen.structure<A.context, B.context, C.context, D.context, E.context, F.context, G.context>
    >
    and type actions<'change> = FieldVector.Actions.t<
      Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input, G.input>,
      'change,
      Gen.structure<
        A.actions<'change>,
        B.actions<'change>,
        C.actions<'change>,
        D.actions<'change>,
        E.actions<'change>,
        F.actions<'change>,
        G.actions<'change>,
      >
    >
    and type pack = Form.t<
      Store.t<
        Gen.structure<A.t, B.t, C.t, D.t, E.t, F.t, G.t>,
        Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output, G.output>,
        error
      >,
      FieldVector.Actions.t<
        Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input, G.input>,
        (),
        Gen.structure<
          A.actions<()>,
          B.actions<()>,
          C.actions<()>,
          D.actions<()>,
          E.actions<()>,
          F.actions<()>,
          G.actions<()>,
        >
      >
    >
    and type parted = Gen.structure<
        Form.t<A.t, A.actions<()>>,
        Form.t<B.t, B.actions<()>>,
        Form.t<C.t, C.actions<()>>,
        Form.t<D.t, D.actions<()>>,
        Form.t<E.t, E.actions<()>>,
        Form.t<F.t, F.actions<()>>,
        Form.t<G.t, G.actions<()>>,
      >

  module Make: Make = (Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T, G: Field.T) => {
    module Inner = FieldVector.Vector7.Make(A, B, C, D, E, F, G)
    type input = Gen.structure<A.input, B.input, C.input, D.input, E.input, F.input, G.input>
    type inner = Gen.structure<A.t, B.t, C.t, D.t, E.t, F.t, G.t>
    type output = Gen.structure<A.output, B.output, C.output, D.output, E.output, F.output, G.output>
    type error = error
    type t = Store.t<inner, output, error>

    type validate = validateOut<output>
    type contextInner = Gen.structure<A.context, B.context, C.context, D.context, E.context, F.context, G.context>
    type context = Context.t<input, validate, contextInner>

    // These are reversed to allow Generic to be legible and Tuple to be packed with A as the inner-most value
    let toTuple: Gen.structure<'a, 'b, 'c, 'd, 'e, 'f, 'g> => T.t<'g, 'f, 'e, 'd, 'c, 'b, 'a> = x => Gen.order->T.encode->T.reverse->T.napply(T.return(x))
    let fromTuple: T.t<'g, 'f, 'e, 'd, 'c, 'b, 'a> => Gen.structure<'a,'b,'c, 'd, 'e, 'f, 'g> = x => x->T.reverse->T.decode->Gen.fromTuple

    let storeToStructure = Store.bimap(_, fromTuple, fromTuple)
    let storeToTuple = Store.bimap(_, toTuple, toTuple)
    let validateToTuple = Option.map(_, v => out => out->fromTuple->v)
    let contextToTuple = (context: context): Inner.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner, validateImmediate: ?context.validateImmediate}
    }

    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Inner.emptyInner->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let set = (x: input): t => x->toTuple->Inner.set->storeToStructure
    let showInput = (x: input) => x->toTuple->Inner.showInput

    let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => 
      Inner.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
      D.actions<'change>,
      E.actions<'change>,
      F.actions<'change>,
      G.actions<'change>,
    >

    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Inner.mapActionsInner(fn)->fromTuple

    type actions<'change> = FieldVector.Actions.t<input, 'change, actionsInner<'change>>
    let mapActions = (actions: actions<'ch> , fn: 'ch => 'b) => actions->FieldVector.Actions.trimap(x => x, fn, mapActionsInner(_, fn))
  
    type pack = Form.t<t, actions<()>>
    type parted =  Gen.structure<
      Form.t<A.t, A.actions<()>>,
      Form.t<B.t, B.actions<()>>,
      Form.t<C.t, C.actions<()>>,
      Form.t<D.t, D.actions<()>>,
      Form.t<E.t, E.actions<()>>,
      Form.t<F.t, F.actions<()>>,
      Form.t<G.t, G.actions<()>>
    >

    let split = (pack: pack) : parted => {
      Inner.splitInner(
        pack.field->Store.inner->toTuple,
        pack.actions.inner->toTuple,
      )
      ->fromTuple
    }

    let actionsFromVector = FieldVector.Actions.trimap(_, toTuple, x=>x, fromTuple)
    let packFromVector = Form.bimap(_, storeToStructure, actionsFromVector)
    let makeDyn = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
      => {
      Inner.makeDyn(context->contextToTuple, initial->Option.map(toTuple), set->Dynamic.map(toTuple), val)
      ->Dyn.map(Close.map(_, packFromVector))
    }

    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Inner.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Inner.printError

    let show = (store: t): string => {
      `Product7{
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Inner.showInner->Array.joinWith(",\n")}
        }
      }`
    }
  }
}
