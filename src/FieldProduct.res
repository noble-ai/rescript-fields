// shadow global Dynamic with the impl chosen by FT

module Tuple = Tuple.Nested
module Change = FieldVector.Change
module Actions = FieldVector.Actions

type error = [#Whole(string) | #Part]
type resultValidate = Promise.t<Result.t<unit, string>>
type validateOut<'out> = 'out => resultValidate

// This module definition lets you  share the FieldProduct code
// but expose the structure given here
// while the FieldProduct stores
module type Interface = {
  // Call async validate when both children become valid
  let validateImmediate: bool
}

module Context = {
  type t<'e, 'v, 'i> = {
    empty?: 'e,
    validate?: 'v,
    inner: 'i,
  }

  // Cant deriving accessors with optional fields?
  let empty = t => t.empty
  let validate = t => t.validate
  let inner = t => t.inner
}

module Product1 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple1

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
      | Either.Right(_) => failwith("impossible")
      }
    }
  }

  module Make = (I: Interface, Gen: Generic, A: Field.T) => {
    module A = A
    module Vector = FieldVector.Vector1.Make(I, A)
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
    let contextToTuple = (context: context): Vector.context => {
      let inner = context.inner->toTuple
      let empty: option<Vector.input> = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toTuple->Vector.showInput

    let set = (x: input): t => x->toTuple->Vector.set->storeToStructure
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Vector.empty->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Vector.printError

    let show = (store: t): string => {
      `Product1{
        validateImmediate: ${I.validateImmediate ? "true" : "false"},
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Vector.showInner->Array.joinWith(",\n")}
        }
      }`
    }

    let makeStore = (~validate, inner: Vector.inner): Dynamic.t<t> => {
      Vector.makeStore(~validate, inner)
      ->Dynamic.map(storeToStructure)
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => 
      Vector.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type changeInner = PolyVariant.t<A.change>
    let changeInnerToVector: changeInner => Vector.changeInner = PolyVariant.toEither
    let changeInnerFromVector: Vector.changeInner => changeInner = PolyVariant.fromEither

    type change = Change.t<input, changeInner>
    let makeSet = Change.makeSet
    let changeToVector: change => Vector.change = Change.bimap(toTuple, changeInnerToVector)
    let changeFromVector: Vector.change => change = Change.bimap(fromTuple, PolyVariant.fromEither)

    let showChange = (change) => change->changeToVector->Vector.showChange

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
    >
    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Vector.mapActionsInner(fn)->fromTuple

    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let actions: actions<change> = Vector.actions->Actions.trimap(toTuple, changeFromVector, x => x->Vector.mapActionsInner(changeFromVector)->fromTuple)
    let mapActions = (actions, fn) => actions->Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Vector.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToTuple), change->Indexed.map(changeToVector))
      ->Dynamic.map(storeToStructure)
    }

    let input = (store: t) => store->storeToTuple->Vector.input->fromTuple
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

  module Make = (I: Interface, Gen: Generic, A: Field.T, B: Field.T) => {
    module A = A
    module B = B
    module Vector = FieldVector.Vector2.Make(I, A, B)

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
    let contextToTuple = (context: context): Vector.context => {
      let inner = context.inner->toTuple
      let empty: option<Vector.input> = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toTuple->Vector.showInput

    let set = (x: input): t => x->toTuple->Vector.set->storeToStructure
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Vector.empty->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Vector.printError

    let show = (store: t): string => {
      `Product2{
        validateImmediate: ${I.validateImmediate ? "true" : "false"},
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Vector.showInner->Array.joinWith(",\n")}
        }
      }`
    }

    let makeStore = (~validate, inner: Vector.inner): Dynamic.t<t> => {
      Vector.makeStore(~validate, inner)
      ->Dynamic.map(storeToStructure)
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => 
      Vector.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type changeInner = PolyVariant.t<B.change, A.change>
    let changeInnerToVector: changeInner => Vector.changeInner = PolyVariant.toEither
    let changeInnerFromVector: Vector.changeInner => changeInner = PolyVariant.fromEither

    type change = Change.t<input, changeInner>
    let makeSet = Change.makeSet
    let changeToVector: change => Vector.change = Change.bimap(toTuple, changeInnerToVector)
    let changeFromVector: Vector.change => change = Change.bimap(fromTuple, PolyVariant.fromEither)

    let showChange = (change) => change->changeToVector->Vector.showChange

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>
    >
    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Vector.mapActionsInner(fn)->fromTuple

    let actionsInner: actionsInner<changeInner> =
      Vector.actionsInner
      ->Vector.mapActionsInner(changeInnerFromVector)
      ->fromTuple
    
    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let actions: actions<change> = Actions.make(actionsInner->mapActionsInner(x => #Inner(x)))
    let mapActions = (actions: actions<'ch> , fn: 'ch => 'b): actions<'b> => actions->Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Vector.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToTuple), change->Indexed.map(changeToVector))
      ->Dynamic.map(storeToStructure)
    }

    let input = (store: t) => store->storeToTuple->Vector.input->fromTuple
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

  module Make = (I: Interface, Gen: Generic, A: Field.T, B: Field.T, C: Field.T) => {
    module Vector = FieldVector.Vector3.Make(I, A, B, C)
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
    let contextToTuple = (context: context): Vector.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toTuple->Vector.showInput

    let set = (x: input): t => x->toTuple->Vector.set->storeToStructure
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Vector.empty->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let makeStore = (~validate, inner: Vector.inner): Dynamic.t<t> => {
      Vector.makeStore(~validate, inner)
      ->Dynamic.map(storeToStructure)
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => 
      Vector.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type changeInner = PolyVariant.t<C.change, B.change, A.change>
    let changeInnerToVector: changeInner => Vector.changeInner = PolyVariant.toEither
    let changeInnerFromVector: Vector.changeInner => changeInner = PolyVariant.fromEither

    type change = Change.t<input, changeInner>
    let makeSet = Change.makeSet
    let changeToVector: change => Vector.change = Change.bimap(toTuple, changeInnerToVector)
    let changeFromVector: Vector.change => change = Change.bimap(fromTuple, PolyVariant.fromEither)

    let showChange = (change) => change->changeToVector->Vector.showChange

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
    >
    
    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Vector.mapActionsInner(fn)->fromTuple

    let actionsInner: actionsInner<changeInner> =
      Vector.actionsInner
      ->Vector.mapActionsInner(changeInnerFromVector)
      ->fromTuple
    
    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let actions: actions<change> = Actions.make(actionsInner->mapActionsInner(x => #Inner(x)))
    let mapActions = (actions: actions<'ch>, fn: 'ch => 'b) => actions->Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    // Cant move this into Vectors as it causes some types to "escape"
    // let const = T.make(const, const, const)
    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Vector.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToTuple), change->Indexed.map(changeToVector))
      ->Dynamic.map(storeToStructure)
    }

    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Vector.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Vector.printError

    let show = (store: t): string => {
      `Product3{
        validateImmediate: ${I.validateImmediate ? "true" : "false"},
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Vector.showInner->Array.joinWith(",\n")}
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

  module Make = (I: Interface, Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T) => {
    module Vector = FieldVector.Vector4.Make(I, A, B, C, D)
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
    let contextToTuple = (context: context): Vector.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toTuple->Vector.showInput

    let set = (x: input) => x->toTuple->Vector.set->storeToStructure
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Vector.empty->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let makeStore = (~validate, inner: Vector.inner): Dynamic.t<t> => {
      Vector.makeStore(~validate, inner)
      ->Dynamic.map(storeToStructure)
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => 
      Vector.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type changeInner = PolyVariant.t<D.change, C.change, B.change, A.change>
    let changeInnerToVector: changeInner => Vector.changeInner = PolyVariant.toEither
    let changeInnerFromVector: Vector.changeInner => changeInner = PolyVariant.fromEither
 
    type change = Change.t<input, changeInner>
    let makeSet = Change.makeSet
    let changeToVector: change => Vector.change = Change.bimap(toTuple, changeInnerToVector)
    let changeFromVector: Vector.change => change = Change.bimap(fromTuple, PolyVariant.fromEither)

    let showChange = (change) => change->changeToVector->Vector.showChange

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
      D.actions<'change>,
    >
    
    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Vector.mapActionsInner(fn)->fromTuple

    let actionsInner: actionsInner<changeInner> =
      Vector.actionsInner
      ->Vector.mapActionsInner(changeInnerFromVector)
      ->fromTuple

    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let actions: actions<change> = Actions.make(actionsInner->mapActionsInner(x => #Inner(x)))
    let mapActions = (actions: actions<'ch>, fn: 'ch => 'b) => actions->Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Vector.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToTuple), change->Indexed.map(changeToVector))
      ->Dynamic.map(storeToStructure)
    }

    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Vector.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = (store: t) => store->storeToTuple->Vector.printError

    let show = (store: t): string => {
      `Product4{
        validateImmediate: ${I.validateImmediate ? "true" : "false"},
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Vector.showInner->Array.joinWith(",\n")}
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

  module Make = (I: Interface, Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T) => {
    module Vector = FieldVector.Vector5.Make(I, A, B, C, D, E)
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
    let contextToTuple = (context: context): Vector.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner}
    }

    let showInput = (x: input) => x->toTuple->Vector.showInput
    let set = (x: input): t => x->toTuple->Vector.set->storeToStructure
    
    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Vector.empty->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let makeStore = (~validate, inner: Vector.inner): Dynamic.t<t> => {
      Vector.makeStore(~validate, inner)
      ->Dynamic.map(storeToStructure)
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => 
      Vector.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type changeInner = PolyVariant.t<E.change, D.change, C.change, B.change, A.change>
    let changeInnerToVector: changeInner => Vector.changeInner = PolyVariant.toEither
    let changeInnerFromVector: Vector.changeInner => changeInner = PolyVariant.fromEither

    type change = Change.t<input, changeInner>
    let makeSet = Change.makeSet
    let changeToVector: change => Vector.change = Change.bimap(toTuple, changeInnerToVector)
    let changeFromVector: Vector.change => change = Change.bimap(fromTuple, PolyVariant.fromEither)

    let showChange = (change) => change->changeToVector->Vector.showChange

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
      D.actions<'change>,
      E.actions<'change>
    >

    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Vector.mapActionsInner(fn)->fromTuple

    let actionsInner: actionsInner<changeInner> =
      Vector.actionsInner
      ->Vector.mapActionsInner(changeInnerFromVector)
      ->fromTuple
    
    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let actions: actions<change> = Actions.make(actionsInner->mapActionsInner(x => #Inner(x)))
    let mapActions = (actions: actions<'ch>, fn: 'ch => 'b) => actions->Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Vector.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToTuple), change->Indexed.map(changeToVector))
      ->Dynamic.map(storeToStructure)
    }

    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Vector.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Vector.printError

    let show = (store: t): string => {
      `Product5{
        validateImmediate: ${I.validateImmediate ? "true" : "false"},
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Vector.showInner->Array.joinWith(",\n")}
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

  module Make = (I: Interface, Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T) => {
    module Vector = FieldVector.Vector6.Make(I, A, B, C, D, E, F)
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
    let contextToTuple = (context: context): Vector.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner}
    }

    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Vector.empty->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let set = (x: input): t => x->toTuple->Vector.set->storeToStructure
    let showInput = (x: input) => x->toTuple->Vector.showInput

    let makeStore = (~validate, inner: Vector.inner): Dynamic.t<t> => {
      Vector.makeStore(~validate, inner)
      ->Dynamic.map(storeToStructure)
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => 
      Vector.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type changeInner = PolyVariant.t<F.change, E.change, D.change, C.change, B.change, A.change>
    let changeInnerToVector: changeInner => Vector.changeInner = PolyVariant.toEither
    let changeInnerFromVector: Vector.changeInner => changeInner = PolyVariant.fromEither
 
    type change = Change.t<input, changeInner>
    let makeSet = Change.makeSet
    let changeToVector: change => Vector.change = Change.bimap(toTuple, changeInnerToVector)
    let changeFromVector: Vector.change => change = Change.bimap(fromTuple, PolyVariant.fromEither)

    let showChange = (change) => change->changeToVector->Vector.showChange

    type actionsInner<'change> = Gen.structure<
      A.actions<'change>,
      B.actions<'change>,
      C.actions<'change>,
      D.actions<'change>,
      E.actions<'change>,
      F.actions<'change>,
    >

    let mapActionsInner = (actions: actionsInner<'c>, fn: 'c => 'd): actionsInner<'d> => 
      actions->toTuple->Vector.mapActionsInner(fn)->fromTuple

    let actionsInner: actionsInner<changeInner> =
      Vector.actionsInner
      ->Vector.mapActionsInner(changeInnerFromVector)
      ->fromTuple
    
    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let actions: actions<change> = Actions.make(actionsInner->mapActionsInner(x => #Inner(x)))
    let mapActions = (actions: actions<'ch>, fn: 'ch => 'b) => actions->Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Vector.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToTuple), change->Indexed.map(changeToVector))
      ->Dynamic.map(storeToStructure)
    }

    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Vector.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Vector.printError

    let show = (store: t): string => {
      `Product6{
        validateImmediate: ${I.validateImmediate ? "true" : "false"},
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Vector.showInner->Array.joinWith(",\n")}
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

  module Make = (I: Interface, Gen: Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T, G: Field.T) => {
    module Vector = FieldVector.Vector7.Make(I, A, B, C, D, E, F, G)
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
    let contextToTuple = (context: context): Vector.context => {
      let inner = context.inner->toTuple
      let empty = context.empty->Option.map(toTuple)
      let validate = context.validate->validateToTuple
      {?empty, ?validate, inner}
    }

    let empty = (context): inner => context->contextToTuple->FieldVector.Context.inner->Vector.empty->fromTuple
    let init = (context: context): t => context->empty->Store.init

    let set = (x: input): t => x->toTuple->Vector.set->storeToStructure
    let showInput = (x: input) => x->toTuple->Vector.showInput

    let makeStore = (~validate, inner: Vector.inner): Dynamic.t<t> => {
      Vector.makeStore(~validate, inner)
      ->Dynamic.map(storeToStructure)
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => 
      Vector.validate(force, context->contextToTuple, store->storeToTuple)
      ->Dynamic.map(storeToStructure)

    type changeInner = PolyVariant.t<G.change, F.change, E.change, D.change, C.change, B.change, A.change>
    let changeInnerToVector: changeInner => Vector.changeInner = PolyVariant.toEither
    let changeInnerFromVector: Vector.changeInner => changeInner = PolyVariant.fromEither
 
    type change = Change.t<input, changeInner>
    let makeSet = Change.makeSet
    let changeToVector: change => Vector.change = Change.bimap(toTuple, changeInnerToVector)
    let changeFromVector: Vector.change => change = Change.bimap(fromTuple, PolyVariant.fromEither)

    let showChange = (change) => change->changeToVector->Vector.showChange

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
      actions->toTuple->Vector.mapActionsInner(fn)->fromTuple

    let actionsInner: actionsInner<changeInner> =
      Vector.actionsInner
      ->Vector.mapActionsInner(changeInnerFromVector)
      ->fromTuple
    
    type actions<'change> = Actions.t<input, 'change, actionsInner<'change>>
    let actions: actions<change> = Actions.make(actionsInner->mapActionsInner(x => #Inner(x)))
    let mapActions = (actions: actions<'ch> , fn: 'ch => 'b) => actions->Actions.trimap(x => x, fn, mapActionsInner(_, fn))

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Vector.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToTuple), change->Indexed.map(changeToVector))
      ->Dynamic.map(storeToStructure)
    }

    let inner = Store.inner

    let input = (store: t) => store->storeToTuple->Vector.input->fromTuple

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    
    let printError = (store: t) => store->storeToTuple->Vector.printError

    let show = (store: t): string => {
      `Product7{
        validateImmediate: ${I.validateImmediate ? "true" : "false"},
        state: ${store->enum->Store.enumToPretty},
        error: ${store->printError->Option.or("None")},
        children: {
          ${store->inner->toTuple->Vector.showInner->Array.joinWith(",\n")}
        }
      }`
    }
  }
}
