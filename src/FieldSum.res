// prefer shadowing Dynamic
open FieldProduct

module Sum1 = {
  module Tuple = Product1.Tuple
  module T = Product1.T

  type sum<'a> = Product1.PolyVariant.t<'a>

  module type Interface = {
    // A variant type that has values of our own choosing
    type t<'a>
    let toSum: t<'a> => sum<'a>
    let fromSum: sum<'a> => t<'a>
    let validateImmediate: bool
  }

  module Context = FieldEither.Context

  //Sum needs Product for maintaining context
  // TODO: Rename as Make
  module Field = (S: Interface, P: Product1.Generic, A: Field.T) => {
    module T = Product1.T
    module Inner = FieldEither.Either1.Make(S, A)
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

    let toEither = (s: S.t<'a>): either<'a> => s->S.toSum->Product1.PolyVariant.toEither
    let fromEither: either<'a> => S.t<'a> = x => x->Product1.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither= Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, v => out => out->fromEither->v)
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

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)
      ->Dynamic.map(storeToSum)
    }

    type changeInner = S.t<A.change>
    type change = FieldVector.Change.t<input, changeInner>
    let makeSet = (input: input): change => #Set(input)
    let changeToEither: change => Inner.change = FieldVector.Change.bimap(toEither, toEither)
    let showChange = (c: change): string => c->changeToEither->Inner.showChange

    type actions = P.structure<A.change => change>

    let actions: actions = 
      (a => #Inner(#A(a)->S.fromSum))->P.fromTuple

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Inner.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToEither), change->Indexed.map(changeToEither))
      ->Dynamic.map(storeToSum)
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
    // let toSum: t<'a, 'b> => sum<'a, 'b>
    // let fromSum: sum<'a, 'b> => t<'a, 'b>
    let validateImmediate: bool
  }

  module Context = FieldEither.Context

  //Sum needs Product for maintaining context
  // TODO: Rename as Make
  module Field = (S: Interface, P: Product2.Generic, A: Field.T, B: Field.T) => {
    module T = Product2.T
    module Inner = FieldEither.Either2.Make(S, A, B)
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
    let fromEither: either<'a, 'b> => S.t<'a, 'b> = x => x->Product2.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither= Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, v => out => out->fromEither->v)
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

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)
      ->Dynamic.map(storeToSum)
    }

    type changeInner = S.t<A.change, B.change>
    type change = FieldVector.Change.t<input, changeInner>
    let makeSet = (input: input): change => #Set(input)
    let changeToEither: change => Inner.change = FieldVector.Change.bimap(toEither, toEither)
    let showChange = (c: change): string => c->changeToEither->Inner.showChange

    type actionsInner<'out> = P.structure<A.change => 'out, B.change => 'out>
    // let actionsInner: actionsInner<changeInner> = Inner.mapActionsInner(fromEither, Inner.actionsInner)->fromTuple

		type actions = FieldVector.Actions.t<input, changeInner, actionsInner<change>>	
		let actions: actions = {
			set: makeSet,
			clear: () => #Clear,
			inner: Inner.actionsInner->Inner.mapActionsInner(x => #Inner(fromEither(x)), _)->fromTuple,
			validate: () => #Validate,
		}

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Inner.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToEither), change->Indexed.map(changeToEither))
      ->Dynamic.map(storeToSum)
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
    let validateImmediate: bool
  }

  module Context = FieldEither.Context

  //Sum needs Product for maintaining context
  // TODO: Rename as Make
  module Field = (S: Interface, P: Product3.Generic, A: Field.T, B: Field.T, C: Field.T) => {
    module T = Product3.T
    module Inner = FieldEither.Either3.Make(S, A, B, C)
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
    let toTuple: P.structure<'a, 'b, 'c> => T.t<'a, 'b, 'c> = x => P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b, 'c> => P.structure<'a, 'b, 'c> = x => x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b, 'c>): either<'a, 'b, 'c> => s->S.toSum->Product3.PolyVariant.toEither
    let fromEither: either<'a, 'b, 'c> => S.t<'a, 'b, 'c> = x => x->Product3.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither= Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, v => out => out->fromEither->v)
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

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)
      ->Dynamic.map(storeToSum)
    }

    type changeInner = S.t<A.change, B.change, C.change>
    type change = FieldVector.Change.t<input, changeInner>
    let makeSet = (input: input): change => #Set(input)
    let changeToEither: change => Inner.change = FieldVector.Change.bimap(toEither, toEither)
    let showChange = (c: change): string => c->changeToEither->Inner.showChange

    type actionsInner<'out> = P.structure<A.change => 'out, B.change => 'out, C.change => 'out>
    // let actionsInner: actionsInner<changeInner> = Inner.mapActionsInner(fromEither, Inner.actionsInner)->fromTuple

		type actions = FieldVector.Actions.t<input, changeInner, actionsInner<change>>	
		let actions: actions = {
			set: makeSet,
			clear: () => #Clear,
			inner: Inner.actionsInner->Inner.mapActionsInner(x => #Inner(fromEither(x)), _)->fromTuple,
			validate: () => #Validate,
		}

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Inner.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToEither), change->Indexed.map(changeToEither))
      ->Dynamic.map(storeToSum)
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
    let validateImmediate: bool
  }

  module Context = FieldEither.Context

  //Sum needs Product for maintaining context
  // TODO: Rename as Make
  module Field = (S: Interface, P: Product4.Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T) => {
    module T = Product4.T
    module Inner = FieldEither.Either4.Make(S, A, B, C, D)
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
    let toTuple: P.structure<'a, 'b, 'c, 'd> => T.t<'a, 'b, 'c, 'd> = x => P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b, 'c, 'd> => P.structure<'a, 'b, 'c, 'd> = x => x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b, 'c, 'd>): either<'a, 'b, 'c, 'd> => s->S.toSum->Product4.PolyVariant.toEither
    let fromEither: either<'a, 'b, 'c, 'd> => S.t<'a, 'b, 'c, 'd> = x => x->Product4.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither= Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, v => out => out->fromEither->v)
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

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)
      ->Dynamic.map(storeToSum)
    }

    type changeInner = S.t<A.change, B.change, C.change, D.change>
    type change = FieldVector.Change.t<input, changeInner>
    let makeSet = (input: input): change => #Set(input)
    let changeToEither: change => Inner.change = FieldVector.Change.bimap(toEither, toEither)
    let showChange = (c: change): string => c->changeToEither->Inner.showChange

    type actionsInner<'out> = P.structure<A.change => 'out, B.change => 'out, C.change => 'out, D.change => 'out>
    // let actionsInner: actionsInner<changeInner> = Inner.mapActionsInner(fromEither, Inner.actionsInner)->fromTuple

		type actions = FieldVector.Actions.t<input, changeInner, actionsInner<change>>	
		let actions: actions = {
			set: makeSet,
			clear: () => #Clear,
			inner: Inner.actionsInner->Inner.mapActionsInner(x => #Inner(fromEither(x)), _)->fromTuple,
			validate: () => #Validate,
		}

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Inner.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToEither), change->Indexed.map(changeToEither))
      ->Dynamic.map(storeToSum)
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
    let validateImmediate: bool
  }

  module Context = FieldEither.Context

  //Sum needs Product for maintaining context
  // TODO: Rename as Make
  module Field = (S: Interface, P: Product5.Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T) => {
    module T = Product5.T
    module Inner = FieldEither.Either5.Make(S, A, B, C, D, E)
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
    let toTuple: P.structure<'a, 'b, 'c, 'd, 'e> => T.t<'a, 'b, 'c, 'd, 'e> = x => P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b, 'c, 'd, 'e> => P.structure<'a, 'b, 'c, 'd, 'e> = x => x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b, 'c, 'd, 'e>): either<'a, 'b, 'c, 'd, 'e> => s->S.toSum->Product5.PolyVariant.toEither
    let fromEither: either<'a, 'b, 'c, 'd, 'e> => S.t<'a, 'b, 'c, 'd, 'e> = x => x->Product5.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither= Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, v => out => out->fromEither->v)
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

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)
      ->Dynamic.map(storeToSum)
    }

    type changeInner = S.t<A.change, B.change, C.change, D.change, E.change>
    type change = FieldVector.Change.t<input, changeInner>
    let makeSet = (input: input): change => #Set(input)
    let changeToEither: change => Inner.change = FieldVector.Change.bimap(toEither, toEither)
    let showChange = (c: change): string => c->changeToEither->Inner.showChange

    type actionsInner<'out> = P.structure<A.change => 'out, B.change => 'out, C.change => 'out, D.change => 'out, E.change => 'out>
    // let actionsInner: actionsInner<changeInner> = Inner.mapActionsInner(fromEither, Inner.actionsInner)->fromTuple

		type actions = FieldVector.Actions.t<input, changeInner, actionsInner<change>>	
		let actions: actions = {
			set: makeSet,
			clear: () => #Clear,
			inner: Inner.actionsInner->Inner.mapActionsInner(x => #Inner(fromEither(x)), _)->fromTuple,
			validate: () => #Validate,
		}

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Inner.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToEither), change->Indexed.map(changeToEither))
      ->Dynamic.map(storeToSum)
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
    let validateImmediate: bool
  }

  module Context = FieldEither.Context

  //Sum needs Product for maintaining context
  // TODO: Rename as Make
  module Field = (S: Interface, P: Product6.Generic, A: Field.T, B: Field.T, C: Field.T, D: Field.T, E: Field.T, F: Field.T) => {
    module T = Product6.T
    module Inner = FieldEither.Either6.Make(S, A, B, C, D, E, F)
    type either<'a, 'b, 'c, 'd, 'e, 'f> = Either.Nested.t6<'a, 'b, 'c, 'd, 'e, 'f>

    type input = S.t<A.input, B.input, C.input, D.input, E.input, F.input>
    type inner = S.t<A.t, B.t, C.t, D.t, E.t, F.t>
    type output = S.t<A.output, B.output, C.output, D.output, E.output, F.output>
    type error = [#Whole(string) | #Part]
    
    type t = Store.t<inner, output, error>

    type validate = FieldVector.validateOut<output>
    type contextInner = P.structure<A.context, B.context, C.context, D.context, E.context, F.context>
    type context = Context.t<input, validate, contextInner>

    // Context is the product equivalent of this sum, so we need toTuple in x->S.toSum->FieldProduct.Product1.PolyVariant.toEither
    let toTuple: P.structure<'a, 'b, 'c, 'd, 'e, 'f> => T.t<'a, 'b, 'c, 'd, 'e, 'f> = x => P.order->T.encode->T.napply(T.return(x))
    let fromTuple: T.t<'a, 'b, 'c, 'd, 'e, 'f> => P.structure<'a, 'b, 'c, 'd, 'e, 'f> = x => x->T.decode->P.fromTuple

    let toEither = (s: S.t<'a, 'b, 'c, 'd, 'e, 'f>): either<'a, 'b, 'c, 'd, 'e, 'f> => s->S.toSum->Product6.PolyVariant.toEither
    let fromEither: either<'a, 'b, 'c, 'd, 'e, 'f> => S.t<'a, 'b, 'c, 'd, 'e, 'f> = x => x->Product6.PolyVariant.fromEither->S.fromSum

    let storeToSum = Store.bimap(_, fromEither, fromEither)
    let storeToEither= Store.bimap(_, toEither, toEither)

    let validateToEither = Option.map(_, v => out => out->fromEither->v)
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

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      Inner.validate(force, context->contextToTuple, store->storeToEither)
      ->Dynamic.map(storeToSum)
    }

    type changeInner = S.t<A.change, B.change, C.change, D.change, E.change, F.change>
    type change = FieldVector.Change.t<input, changeInner>
    let makeSet = (input: input): change => #Set(input)
    let changeToEither: change => Inner.change = FieldVector.Change.bimap(toEither, toEither)
    let showChange = (c: change): string => c->changeToEither->Inner.showChange

    type actionsInner<'out> = P.structure<A.change => 'out, B.change => 'out, C.change => 'out, D.change => 'out, E.change => 'out, F.change => 'out>
    // let actionsInner: actionsInner<changeInner> = Inner.mapActionsInner(fromEither, Inner.actionsInner)->fromTuple

		type actions = FieldVector.Actions.t<input, changeInner, actionsInner<change>>	
		let actions: actions = {
			set: makeSet,
			clear: () => #Clear,
			inner: Inner.actionsInner->Inner.mapActionsInner(x => #Inner(fromEither(x)), _)->fromTuple,
			validate: () => #Validate,
		}

    let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
      Inner.reduce(~context=context->contextToTuple, store->Dynamic.map(storeToEither), change->Indexed.map(changeToEither))
      ->Dynamic.map(storeToSum)
    }

    let input = (store: t): input => store->storeToEither->Inner.input->fromEither
    let inner = Store.inner
    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = store => store->storeToEither->Inner.printError
  }
}