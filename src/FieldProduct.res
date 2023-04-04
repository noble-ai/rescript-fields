
module Tuple = Tuple.Nested

let outputresult = (output, enum, a) => {
  switch a->output {
  | Some(output) => Ok(output)
  | None => Error(a->enum)
  }
}

let resolveErr = (input, e) => {
  switch e {
  | #Busy => Store.busy(input)
  | #Invalid => Store.invalid(input, #Part)
  | #Init => Store.init(input)
  | #Dirty => Store.dirty(input)
  | #Valid => Js.Exn.raiseError("allResult must not fail when #Valid")
  }->Dynamic.return
}

let printErrorArray = errors => {
  errors->Array.catOptions->Js.Array2.joinWith(", ")->Some
}

module Product2 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple2

  // This module definition lets you  share the FieldProduct code
  // but expose the structure given here
  // while the FieldProduct stores
  module type Interface = {
    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module type Generic = {
    type structure<'a, 'b>

    let fromTuple: T.t<'a, 'b> => structure<'a, 'b>
    let toTuple: structure<'a, 'b> => T.t<'a, 'b>
  }

  module Accessors = (G: Generic) => {
    let a = (s: G.structure<'a, 'b>) => s->G.toTuple->get1
    let b = (s: G.structure<'a, 'b>) => s->G.toTuple->get2

    let setA = (s: G.structure<'a, 'b>, a: 'a) => s->G.toTuple->set1(a)
    let setB = (s: G.structure<'a, 'b>, b: 'b) => s->G.toTuple->set2(b)
  }

  module Make = (I: Interface, G: Generic, A: FieldTrip.Field, B: FieldTrip.Field) => {
    module Acc = Accessors(G)

    type input = G.structure<A.input, B.input>
    type inner = G.structure<A.t, B.t>
    type output = G.structure<A.output, B.output>
    type error = [#Whole(string) | #Part]
    type t = Store.t<inner, output, error>

    type validate = output => Js.Promise.t<Belt.Result.t<unit, string>>
    type context = {
      // When the product is valid, this validation is called allowing a check of all fields together
      validate?: validate,
      inner: G.structure<A.context, B.context>,
    }

    // Build structures of functions so the specifics can for this field can be written as vector operations.
    type tupleinner = T.t<A.t, B.t>
    let tupleenum = T.make(A.enum, B.enum)
    let tupleinit = T.make(A.init, B.init)
    let tupleinput = T.make(A.input, B.input)
    let tupleresult = T.make(outputresult(A.output, A.enum), outputresult(B.output, B.enum))
    let tuplePrintError = T.make(A.printError, B.printError)
    let tupleShow = T.make(A.show, B.show)

    let tupleset = T.make(A.set, B.set)
    let tupleValidateImpl = T.make(A.validate, B.validate)

    // TODO: Option produces natural tuples, so we need to reencode
    let allOption: T.t<option<'a>, option<'b>> => option<T.t<'a, 'b>> = x =>
      x->T.uncurry(Option.all2, _)->Option.map(T.encode)
    type allResult<'a, 'b, 'err> = tuple2<Result.t<'a, 'err>, Result.t<'b, 'err>> => Result.t<
      tuple2<'a, 'b>,
      'err,
    >
    let allResult: allResult<'a, 'b, 'err> = x => {
      x->T.uncurry(Result.all2, _)->Result.map(T.encode)
    }

    let allPromise = x => {
      x->T.decode->Dynamic.combineLatest2->Dynamic.map(T.encode)
    }

    let set = (x: input): t => {
      x->G.toTuple->T.napply(tupleset)->G.fromTuple->Store.dirty
    }

    let empty = (context): inner => context.inner->G.toTuple->T.napply(tupleinit)->G.fromTuple

    let init = (context: context) => context->empty->Store.init

    let prefer = (enum, make, inner, input) =>
      // First Prioritize Busy first if any children are busy
      Result.predicate(
        inner->T.mono(tupleenum)->Array.some(x => x == enum),
        make(input)->Dynamic.return,
        #Invalid,
      )

    let makeStore = (~context: context, ~force=false, inner: tupleinner): Dynamic.t<t> => {
      let innerP = G.fromTuple(inner)
      // TODO: These predicated values are computed up front
      // so these promises are made, and then thrown away
      // Should predicate take a thunk for lazy evaluation? - AxM
      [
        // First Prioritize Busy first if any children are busy
        prefer(#Busy, Store.busy, inner, innerP),
        // Then Prioritize Invalid state if any children are invalid
        prefer(#Invalid, Store.invalid(_, #Part), inner, innerP),
        // Otherwise take the first error we find
        T.napply(inner, tupleresult)
        ->allResult
        ->Result.map(out => {
          switch context.validate {
          | Some(validate) if I.validateImmediate || force =>
            validate(G.fromTuple(out))
            ->Dynamic.fromPromise
            ->Dynamic.map(
              Result.resolve(
                ~ok=_ => Store.valid(innerP, G.fromTuple(out)),
                ~err=e => Store.invalid(innerP, #Whole(e)),
              ),
            )
            ->Dynamic.startWith(Store.busy(innerP))
          // When we are given a validate function but not validateImmediate or force, do not assume valid until validated
          | Some(_validate) => Store.dirty(innerP)->Dynamic.return
          | _ => Store.valid(innerP, G.fromTuple(out))->Dynamic.return
          }
        }),
      ]
      ->Js.Array2.reduce(Result.first, Error(#Invalid))
      ->Result.resolve(~ok=x => x, ~err=resolveErr(innerP))
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      if !force && store->Store.toEnum == #Valid {
        store->Dynamic.return
      } else {
        tupleValidateImpl
        ->T.napply(T.return(force), _)
        ->T.napply(context.inner->G.toTuple, _)
        ->T.napply(store->Store.inner->G.toTuple, _)
        ->allPromise
        ->Dynamic.bind(makeStore(~context, ~force=true))
      }
    }

    type change = [#Set(input) | #Clear | #A(A.change) | #B(B.change) | #Validate]
    let tupleactions = T.make(a => #A(a), b => #B(b))
    let actions: G.structure<A.change => change, B.change => change> = G.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let input = store->Dynamic.map(Store.inner)
      let inputT = input->Dynamic.map(G.toTuple)

      let contextInner = context.inner->G.toTuple

      switch change {
      | #Set(input) =>
        input
        ->G.toTuple
        ->T.napply(tupleset)
        ->G.fromTuple
        ->Store.dirty
        ->(
          x => {
            if I.validateImmediate {
              validate(false, context, x)
            } else {
              Dynamic.return(x)
            }
          }
        )

      | #Clear => context->init->Dynamic.return
      | #A(ch) => {
          let get = get1
          let set = set1
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          inputT
          ->Dynamic.map(get)
          ->A.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
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
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #B(ch) => {
          let get = get2
          let set = set2
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          inputT
          ->Dynamic.map(get)
          ->B.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #Validate =>
        store
        ->Dynamic.take(1)
        ->Dynamic.bind(store => {
          validate(false, context, store)
        })
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      store->Store.inner->G.toTuple->T.napply(tupleinput)->G.fromTuple
    }

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(error => {
        switch error {
          | #Whole(error) => error->Some
          | #Part => store->Store.inner->G.toTuple->T.mono(tuplePrintError)->printErrorArray
        }
      })
    }

    let show = (store: t): string => {
      let (a, b) = store->inner->G.toTuple->T.napply(tupleShow)->T.decode
      `Product2{
        state: ${store->enum->Store.Enum.toPretty},
        error: ${store->printError->Option.getWithDefault("<none>")},
        children: {
          a: ${a},
          b: ${b},
        }
      }`
    }
  }
}

module Product3 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple3

  module type Interface = {
    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module type Generic = {
    type structure<'a, 'b, 'c>

    let toTuple: structure<'a, 'b, 'c> => T.t<'a, 'b, 'c>
    let fromTuple: T.t<'a, 'b, 'c> => structure<'a, 'b, 'c>
  }

  // If we have the InterfaceProduct3 Generic representation
  // we can derive these accessors for each field
  module Accessors = (G: Generic) => {
    let a = (s: G.structure<'a, 'b, 'c>): 'a => s->G.toTuple->get1
    let b = (s: G.structure<'a, 'b, 'c>): 'b => s->G.toTuple->get2
    let c = (s: G.structure<'a, 'b, 'c>): 'c => s->G.toTuple->get3

    let setA = (s: G.structure<'a, 'b, 'c>, v: 'a): G.structure<'a, 'b, 'c> =>
      s->G.toTuple->set1(_, v)->G.fromTuple
    let setB = (s: G.structure<'a, 'b, 'c>, v: 'b): G.structure<'a, 'b, 'c> =>
      s->G.toTuple->set2(_, v)->G.fromTuple
    let setC = (s: G.structure<'a, 'b, 'c>, v: 'c): G.structure<'a, 'b, 'c> =>
      s->G.toTuple->set3(_, v)->G.fromTuple
  }

  module Make = (I: Interface, G: Generic, A: FieldTrip.Field, B: FieldTrip.Field, C: FieldTrip.Field) => {
    module Acc = Accessors(G)

    type input = G.structure<A.input, B.input, C.input>
    type inner = G.structure<A.t, B.t, C.t>
    type output = G.structure<A.output, B.output, C.output>
    type error = [#Whole(string) | #Part]

    type validate = output => Js.Promise.t<Belt.Result.t<unit, string>>
    type context = {
      validate?: validate,
      inner: G.structure<A.context, B.context, C.context>,
    }

    type t = Store.t<inner, output, error>

    type tupleinner = T.t<A.t, B.t, C.t>
    let tupleenum = T.make(A.enum, B.enum, C.enum)
    let tupleinit = T.make(A.init, B.init, C.init)
    let tupleinput = T.make(A.input, B.input, C.input)
    let tupleresult = T.make(
      outputresult(A.output, A.enum),
      outputresult(B.output, B.enum),
      outputresult(C.output, C.enum),
    )

    let tuplePrintError = T.make(A.printError, B.printError, C.printError)
    let tupleShow = T.make(A.show, B.show, C.show)
    let tupleset = T.make(A.set, B.set, C.set)
    let tupleValidateImpl = T.make(A.validate, B.validate, C.validate)

    let allResult: tuple3<Result.t<'a, 'err>, Result.t<'b, 'err>, Result.t<'c, 'err>> => Result.t<
      tuple3<'a, 'b, 'c>,
      'err,
    > = x => {
      x->T.uncurry(Result.all3, _)->Result.map(T.encode)
    }

    let allPromise = x => {
      x->T.decode->Dynamic.combineLatest3->Dynamic.map(T.encode)
    }

    let set = (x: input): t => x->G.toTuple->T.napply(tupleset)->G.fromTuple->Store.dirty

    let empty = context => context.inner->G.toTuple->T.napply(tupleinit)->G.fromTuple

    let init = context => context->empty->Store.init

    let prefer = (enum, make, inner, input) =>
      // First Prioritize Busy first if any children are busy
      Result.predicate(
        inner->T.mono(tupleenum)->Array.some(x => x == enum),
        make(input)->Dynamic.return,
        #Invalid,
      )

    let makeStore = (~context: context, ~force=false, inner: tupleinner): Dynamic.t<t> => {
      let innerP = G.fromTuple(inner)
      // TODO: These predicated values are computed up front
      // so these promises are made, and then thrown away
      // Should predicate take a thunk for lazy evaluation? - AxM
      [
        // First Prioritize Busy first if any children are busy
        prefer(#Busy, Store.busy, inner, innerP),
        // Then Prioritize Invalid state if any children are invalid
        prefer(#Invalid, Store.invalid(_, #Part), inner, innerP),
        // Otherwise take the first error we find
        T.napply(inner, tupleresult)
        ->allResult
        ->Result.map(out => {
          switch context.validate {
          | Some(validate) if I.validateImmediate || force =>
            validate(G.fromTuple(out))
            ->Dynamic.fromPromise
            ->Dynamic.map(
              Result.resolve(
                ~ok=_ => Store.valid(innerP, G.fromTuple(out)),
                ~err=e => Store.invalid(innerP, #Whole(e)),
              ),
            )
            ->Dynamic.startWith(Store.busy(innerP))
          // When we are given a validate function but not validateImmediate or force, do not assume valid until validated
          | Some(_validate) => Store.dirty(innerP)->Dynamic.return
          | _ => Store.valid(innerP, G.fromTuple(out))->Dynamic.return
          }
        }),
      ]
      ->Js.Array2.reduce(Result.first, Error(#Invalid))
      ->Result.resolve(~ok=x => x, ~err=resolveErr(innerP))
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      if !force && store->Store.toEnum == #Valid {
        store->Dynamic.return
      } else {
        tupleValidateImpl
        ->T.napply(T.return(force), _)
        ->T.napply(context.inner->G.toTuple, _)
        ->T.napply(store->Store.inner->G.toTuple, _)
        ->allPromise
        ->Dynamic.bind(makeStore(~context, ~force=true))
      }
    }

    type change = [#Set(input) | #Clear | #A(A.change) | #B(B.change) | #C(C.change) | #Validate]

    let tupleactions = T.make(a => #A(a), b => #B(b), c => #C(c))
    let actions: G.structure<
      A.change => change,
      B.change => change,
      C.change => change,
    > = G.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let inner = store->Dynamic.map(Store.inner)
      let innerT = inner->Dynamic.map(G.toTuple)

      let contextInner = context.inner->G.toTuple

      switch change {
      | #Set(input) =>
        input
        ->G.toTuple
        ->T.napply(tupleset)
        ->G.fromTuple
        ->Store.dirty
        ->(
          x => {
            if I.validateImmediate {
              validate(false, context, x)
            } else {
              Dynamic.return(x)
            }
          }
        )

      | #Clear => context->init->Dynamic.return
      | #A(ch) => {
          let get = get1
          let set = set1
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->A.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #B(ch) => {
          let get = get2
          let set = set2
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->B.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #C(ch) => {
          let get = get3
          let set = set3
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->C.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #Validate =>
        store
        ->Dynamic.take(1)
        ->Dynamic.bind(store => {
          validate(false, context, store)
        })
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      store->Store.inner->G.toTuple->T.napply(tupleinput)->G.fromTuple
    }

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(error => {
        switch error {
          | #Whole(error) => error->Some
          | #Part => store->Store.inner->G.toTuple->T.mono(tuplePrintError)->printErrorArray
        }
      })
    }


    let show = (store: t): string => {
      let (a, b, c) = store->inner->G.toTuple->T.napply(tupleShow)->T.decode
      `Product3{
        state: ${store->enum->Store.Enum.toPretty},
        error: ${store->printError->Option.getWithDefault("<none>")},
        childrenn: {
          a: ${a},
          b: ${b},
          c: ${c}
        }}`
    }
  }
}

module Product4 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple4

  module type Interface = {
    let validateImmediate: bool
  }

  module type Generic = {
    type structure<'a, 'b, 'c, 'd>

    let fromTuple: T.t<'a, 'b, 'c, 'd> => structure<'a, 'b, 'c, 'd>
    let toTuple: structure<'a, 'b, 'c, 'd> => T.t<'a, 'b, 'c, 'd>
  }

  module Accessors = (G: Generic) => {
    let a = (s: G.structure<'a, 'b, 'c, 'd>): 'a => s->G.toTuple->get1
    let b = (s: G.structure<'a, 'b, 'c, 'd>): 'b => s->G.toTuple->get2
    let c = (s: G.structure<'a, 'b, 'c, 'd>): 'c => s->G.toTuple->get3
    let d = (s: G.structure<'a, 'b, 'c, 'd>): 'd => s->G.toTuple->get4

    let setA = (s: G.structure<'a, 'b, 'c, 'd>, v: 'a): G.structure<'a, 'b, 'c, 'd> =>
      s->G.toTuple->set1(_, v)->G.fromTuple
    let setB = (s: G.structure<'a, 'b, 'c, 'd>, v: 'b): G.structure<'a, 'b, 'c, 'd> =>
      s->G.toTuple->set2(_, v)->G.fromTuple
    let setC = (s: G.structure<'a, 'b, 'c, 'd>, v: 'c): G.structure<'a, 'b, 'c, 'd> =>
      s->G.toTuple->set3(_, v)->G.fromTuple
    let setD = (s: G.structure<'a, 'b, 'c, 'd>, v: 'd): G.structure<'a, 'b, 'c, 'd> =>
      s->G.toTuple->set4(_, v)->G.fromTuple
  }

  module Make = (I: Interface, G: Generic, A: FieldTrip.Field, B: FieldTrip.Field, C: FieldTrip.Field, D: FieldTrip.Field) => {
    module Acc = Accessors(G)

    type input = G.structure<A.input, B.input, C.input, D.input>
    type inner = G.structure<A.t, B.t, C.t, D.t>
    type output = G.structure<A.output, B.output, C.output, D.output>
    type error = [#Whole(string) | #Part]
    type t = Store.t<inner, output, error>

    type validate = output => Js.Promise.t<Belt.Result.t<unit, string>>
    type context = {
      validate?: validate,
      inner: G.structure<A.context, B.context, C.context, D.context>,
    }

    type tupleinner = T.t<A.t, B.t, C.t, D.t>
    let tupleenum = T.make(A.enum, B.enum, C.enum, D.enum)
    let tupleinit = T.make(A.init, B.init, C.init, D.init)
    let tupleinput = T.make(A.input, B.input, C.input, D.input)
    let tupleresult = T.make(
      outputresult(A.output, A.enum),
      outputresult(B.output, B.enum),
      outputresult(C.output, C.enum),
      outputresult(D.output, D.enum),
    )
    let tuplePrintError = T.make(A.printError, B.printError, C.printError, D.printError)
    let tupleShow = T.make(A.show, B.show, C.show, D.show)
    let tupleset = T.make(A.set, B.set, C.set, D.set)
    let tupleValidateImpl = T.make(A.validate, B.validate, C.validate, D.validate)

    type allResult<'a, 'b, 'c, 'd, 'err> = tuple4<
      Result.t<'a, 'err>,
      Result.t<'b, 'err>,
      Result.t<'c, 'err>,
      Result.t<'d, 'err>,
    > => Result.t<tuple4<'a, 'b, 'c, 'd>, 'err>
    let allResult: allResult<'a, 'b, 'c, 'd, 'err> = x => {
      x->T.uncurry(Result.all4, _)->Result.map(T.encode)
    }

    let allPromise = x => {
      x->T.decode->Dynamic.combineLatest4->Dynamic.map(T.encode)
    }

    let set = (x: input) => x->G.toTuple->T.napply(tupleset)->G.fromTuple->Store.dirty

    let empty = context => context.inner->G.toTuple->T.napply(tupleinit)->G.fromTuple

    let init = context => context->empty->Store.init

    let prefer = (enum, make, inner, input) =>
      // First Prioritize Busy first if any children are busy
      Result.predicate(
        inner->T.mono(tupleenum)->Array.some(x => x == enum),
        make(input)->Dynamic.return,
        #Invalid,
      )

    let makeStore = (~context: context, ~force=false, inner: tupleinner): Dynamic.t<t> => {
      let innerP = G.fromTuple(inner)
      // TODO: These predicated values are computed up front
      // so these promises are made, and then thrown away
      // Should predicate take a thunk for lazy evaluation? - AxM
      [
        // First Prioritize Busy first if any children are busy
        prefer(#Busy, Store.busy, inner, innerP),
        // Then Prioritize Invalid state if any children are invalid
        prefer(#Invalid, Store.invalid(_, #Part), inner, innerP),
        // Otherwise take the first error we find
        T.napply(inner, tupleresult)
        ->allResult
        ->Result.map(out => {
          switch context.validate {
          | Some(validate) if I.validateImmediate || force =>
            validate(G.fromTuple(out))
            ->Dynamic.fromPromise
            ->Dynamic.map(
              Result.resolve(
                ~ok=_ => Store.valid(innerP, G.fromTuple(out)),
                ~err=e => Store.invalid(innerP, #Whole(e)),
              ),
            )
            ->Dynamic.startWith(Store.busy(innerP))
          // When we are given a validate function but not validateImmediate or force, do not assume valid until validated
          | Some(_validate) => Store.dirty(innerP)->Dynamic.return
          | _ => Store.valid(innerP, G.fromTuple(out))->Dynamic.return
          }
        }),
      ]
      ->Js.Array2.reduce(Result.first, Error(#Invalid))
      ->Result.resolve(~ok=x => x, ~err=resolveErr(innerP))
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      if !force && store->Store.toEnum == #Valid {
        store->Dynamic.return
      } else {
        tupleValidateImpl
        ->T.napply(T.return(force), _)
        ->T.napply(context.inner->G.toTuple, _)
        ->T.napply(store->Store.inner->G.toTuple, _)
        ->allPromise
        ->Dynamic.bind(makeStore(~context, ~force=true))
      }
    }

    type change = [
      | #Set(input)
      | #Clear
      | #A(A.change)
      | #B(B.change)
      | #C(C.change)
      | #D(D.change)
      | #Validate
    ]

    let tupleactions = T.make(a => #A(a), b => #B(b), c => #C(c), d => #D(d))
    let actions: G.structure<
      A.change => change,
      B.change => change,
      C.change => change,
      D.change => change,
    > = G.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let input = store->Dynamic.map(Store.inner)->Dynamic.map(G.toTuple)
      let contextInner = context.inner->G.toTuple

      // let input = store->Store.inner
      switch change {
      | #Set(input) =>
        input
        ->G.toTuple
        ->T.napply(tupleset)
        ->G.fromTuple
        ->Store.dirty
        ->(
          x => {
            if I.validateImmediate {
              validate(false, context, x)
            } else {
              Dynamic.return(x)
            }
          }
        )

      | #Clear => context->init->Dynamic.return
      | #A(ch) => {
          let get = get1
          let set = set1
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          input
          ->Dynamic.map(get)
          ->A.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #B(ch) => {
          let get = get2
          let set = set2
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          input
          ->Dynamic.map(get)
          ->B.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #C(ch) => {
          let get = get3
          let set = set3
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          input
          ->Dynamic.map(get)
          ->C.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #D(ch) => {
          let get = get4
          let set = set4
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          input
          ->Dynamic.map(get)
          ->D.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #Validate =>
        store
        ->Dynamic.take(1)
        ->Dynamic.bind(store => {
          validate(false, context, store)
        })
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      store->Store.inner->G.toTuple->T.napply(tupleinput)->G.fromTuple
    }

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum

    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(error => {
        switch error {
          | #Whole(error) => error->Some
          | #Part => store->Store.inner->G.toTuple->T.mono(tuplePrintError)->printErrorArray
        }
      })
    }

    let show = (store: t): string => {
      let (a, b, c, d) = store->inner->G.toTuple->T.napply(tupleShow)->T.decode
      `Product4{
        state: ${store->enum->Store.Enum.toPretty},
        error: ${store->printError->Option.getWithDefault("<none>")},
        children: {
          a: ${a},
          b: ${b},
          c: ${c},
          d: ${d},
        }
      }`
    }

    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(error => {
        switch error {
          | #Whole(error) => error->Some
          | #Part => store->Store.inner->G.toTuple->T.mono(tuplePrintError)->printErrorArray
        }
      })
    }


  }
}

module Product5 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple5

  module type Interface = {
    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module type Generic = {
    type structure<'a, 'b, 'c, 'd, 'e>
    let toTuple: structure<'a, 'b, 'c, 'd, 'e> => T.t<'a, 'b, 'c, 'd, 'e>
    let fromTuple: T.t<'a, 'b, 'c, 'd, 'e> => structure<'a, 'b, 'c, 'd, 'e>
  }

  module Accessors = (G: Generic) => {
    let a = (s: G.structure<'a, 'b, 'c, 'd, 'e>): 'a => s->G.toTuple->get1
    let b = (s: G.structure<'a, 'b, 'c, 'd, 'e>): 'b => s->G.toTuple->get2
    let c = (s: G.structure<'a, 'b, 'c, 'd, 'e>): 'c => s->G.toTuple->get3
    let d = (s: G.structure<'a, 'b, 'c, 'd, 'e>): 'd => s->G.toTuple->get4
    let e = (s: G.structure<'a, 'b, 'c, 'd, 'e>): 'e => s->G.toTuple->get5

    let setA = (s: G.structure<'a, 'b, 'c, 'd, 'e>, v: 'a): G.structure<'a, 'b, 'c, 'd, 'e> =>
      s->G.toTuple->set1(_, v)->G.fromTuple
    let setB = (s: G.structure<'a, 'b, 'c, 'd, 'e>, v: 'b): G.structure<'a, 'b, 'c, 'd, 'e> =>
      s->G.toTuple->set2(_, v)->G.fromTuple
    let setC = (s: G.structure<'a, 'b, 'c, 'd, 'e>, v: 'c): G.structure<'a, 'b, 'c, 'd, 'e> =>
      s->G.toTuple->set3(_, v)->G.fromTuple
    let setD = (s: G.structure<'a, 'b, 'c, 'd, 'e>, v: 'd): G.structure<'a, 'b, 'c, 'd, 'e> =>
      s->G.toTuple->set4(_, v)->G.fromTuple
    let setE = (s: G.structure<'a, 'b, 'c, 'd, 'e>, v: 'e): G.structure<'a, 'b, 'c, 'd, 'e> =>
      s->G.toTuple->set5(_, v)->G.fromTuple
  }

  module Make = (I: Interface, G: Generic, A: FieldTrip.Field, B: FieldTrip.Field, C: FieldTrip.Field, D: FieldTrip.Field, E: FieldTrip.Field) => {
    module Acc = Accessors(G)

    type input = G.structure<A.input, B.input, C.input, D.input, E.input>
    type inner = G.structure<A.t, B.t, C.t, D.t, E.t>
    type error = [#Whole(string) | #Part]
    type output = G.structure<A.output, B.output, C.output, D.output, E.output>
    type t = Store.t<inner, output, error>

    type validate = output => Js.Promise.t<Belt.Result.t<unit, string>>
    type context = {
      validate?: validate,
      inner: G.structure<A.context, B.context, C.context, D.context, E.context>,
    }

    type tupleinner = T.t<A.t, B.t, C.t, D.t, E.t>
    let tupleenum = T.make(A.enum, B.enum, C.enum, D.enum, E.enum)
    let tupleinit = T.make(A.init, B.init, C.init, D.init, E.init)
    let tupleinput = T.make(A.input, B.input, C.input, D.input, E.input)
    let tupleresult = T.make(
      outputresult(A.output, A.enum),
      outputresult(B.output, B.enum),
      outputresult(C.output, C.enum),
      outputresult(D.output, D.enum),
      outputresult(E.output, E.enum),
    )
    let tuplePrintError = T.make(
      A.printError,
      B.printError,
      C.printError,
      D.printError,
      E.printError,
    )
    let tupleShow = T.make(A.show, B.show, C.show, D.show, E.show)
    let tupleset = T.make(A.set, B.set, C.set, D.set, E.set)
    let tupleValidateImpl = T.make(A.validate, B.validate, C.validate, D.validate, E.validate)

    type allResult<'a, 'b, 'c, 'd, 'e, 'err> = tuple5<
      Result.t<'a, 'err>,
      Result.t<'b, 'err>,
      Result.t<'c, 'err>,
      Result.t<'d, 'err>,
      Result.t<'e, 'err>,
    > => Result.t<tuple5<'a, 'b, 'c, 'd, 'e>, 'err>
    let allResult: allResult<'a, 'b, 'c, 'd, 'e, 'err> = x => {
      x->T.uncurry(Result.all5, _)->Result.map(T.encode)
    }

    let allPromise = x => {
      x->T.decode->Dynamic.combineLatest5->Dynamic.map(T.encode)
    }

    let set = (x: input) => x->G.toTuple->T.napply(tupleset)->G.fromTuple->Store.dirty

    let empty: context => inner = context =>
      context.inner->G.toTuple->T.napply(tupleinit)->G.fromTuple

    let init = context => context->empty->Store.init

    let prefer = (enum, make, inner, input) =>
      // First Prioritize Busy first if any children are busy
      Result.predicate(
        inner->T.mono(tupleenum)->Array.some(x => x == enum),
        make(input)->Dynamic.return,
#Invalid,
      )

    let makeStore = (~context: context, ~force=false, inner: tupleinner): Dynamic.t<t> => {
      let innerP = G.fromTuple(inner)
      // TODO: These predicated values are computed up front
      // so these promises are made, and then thrown away
      // Should predicate take a thunk for lazy evaluation? - AxM
      [
        // First Prioritize Busy first if any children are busy
        prefer(#Busy, Store.busy, inner, innerP),
        // Then Prioritize Invalid state if any children are invalid
        prefer(#Invalid, Store.invalid(_, #Part), inner, innerP),
        // Otherwise take the first error we find
        T.napply(inner, tupleresult)
        ->allResult
        ->Result.map(out => {
          switch context.validate {
          | Some(validate) if I.validateImmediate || force =>
            validate(G.fromTuple(out))
            ->Dynamic.fromPromise
            ->Dynamic.map(
              Result.resolve(
                ~ok=_ => Store.valid(innerP, G.fromTuple(out)),
                ~err=e => Store.invalid(innerP, #Whole(e)),
              ),
            )
            ->Dynamic.startWith(Store.busy(innerP))
          // When we are given a validate function but not validateImmediate or force, do not assume valid until validated
          | Some(_validate) => Store.dirty(innerP)->Dynamic.return
          | _ => Store.valid(innerP, G.fromTuple(out))->Dynamic.return
          }
        }),
      ]
      ->Js.Array2.reduce(Result.first, Error(#Invalid))
      ->Result.resolve(~ok=x => x, ~err=resolveErr(innerP))
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      if !force && store->Store.toEnum == #Valid {
        store->Dynamic.return
      } else {
        tupleValidateImpl
        ->T.napply(T.return(force), _)
        ->T.napply(context.inner->G.toTuple, _)
        ->T.napply(store->Store.inner->G.toTuple, _)
        ->allPromise
        ->Dynamic.bind(makeStore(~context, ~force=true))
      }
    }

    type change = [
      | #Set(input)
      | #Clear
      | #A(A.change)
      | #B(B.change)
      | #C(C.change)
      | #D(D.change)
      | #E(E.change)
      | #Validate
    ]

    let tupleactions = T.make(a => #A(a), b => #B(b), c => #C(c), d => #D(d), e => #E(e))
    let actions: G.structure<
      A.change => change,
      B.change => change,
      C.change => change,
      D.change => change,
      E.change => change,
    > = G.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let inner = store->Dynamic.map(Store.inner)
      let innerT = inner->Dynamic.map(G.toTuple)

      let contextInner = context.inner->G.toTuple

      switch change {
      | #Set(input) =>
        input
        ->G.toTuple
        ->T.napply(tupleset)
        ->G.fromTuple
        ->Store.dirty
        ->(
          x => {
            if I.validateImmediate {
              validate(false, context, x)
            } else {
              Dynamic.return(x)
            }
          }
        )

      | #Clear => context->init->Dynamic.return
      | #A(ch) => {
          let get = get1
          let set = set1
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->A.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #B(ch) => {
          let get = get2
          let set = set2
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->B.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #C(ch) => {
          let get = get3
          let set = set3
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->C.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #D(ch) => {
          let get = get4
          let set = set4
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->D.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #E(ch) => {
          let get = get5
          let set = set5
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->E.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #Validate =>
        store
        ->Dynamic.take(1)
        ->Dynamic.bind(store => {
          validate(false, context, store)
        })
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      store->Store.inner->G.toTuple->T.napply(tupleinput)->G.fromTuple
    }

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(error => {
        switch error {
          | #Whole(error) => error->Some
          | #Part => store->Store.inner->G.toTuple->T.mono(tuplePrintError)->printErrorArray
        }
      })
    }


    let show = (store: t): string => {
      let (a, b, c, d, e) = store->inner->G.toTuple->T.napply(tupleShow)->T.decode
      `Product5{
        state: ${store->enum->Store.Enum.toPretty},
        error: ${store->printError->Option.getWithDefault("<none>")},
        children: {
          a: ${a},
          b: ${b},
          c: ${c},
          d: ${d},
          e: ${e},
        }
      }`
    }
  }
}

module Product6 = {
  module Tuple = Tuple
  open Tuple
  module T = Tuple6

  module type Interface = {
    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module type Generic = {
    type structure<'a, 'b, 'c, 'd, 'e, 'f>
    let toTuple: structure<'a, 'b, 'c, 'd, 'e, 'f> => T.t<'a, 'b, 'c, 'd, 'e, 'f>
    let fromTuple: T.t<'a, 'b, 'c, 'd, 'e, 'f> => structure<'a, 'b, 'c, 'd, 'e, 'f>
  }

  module Accessors = (G: Generic) => {
    let a = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>): 'a => s->G.toTuple->get1
    let b = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>): 'b => s->G.toTuple->get2
    let c = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>): 'c => s->G.toTuple->get3
    let d = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>): 'd => s->G.toTuple->get4
    let e = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>): 'e => s->G.toTuple->get5
    let f = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>): 'f => s->G.toTuple->get6

    let setA = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>, v: 'a): G.structure<'a, 'b, 'c, 'd, 'e, 'f> => s->G.toTuple->set1(_, v)->G.fromTuple
    let setB = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>, v: 'b): G.structure<'a, 'b, 'c, 'd, 'e, 'f> => s->G.toTuple->set2(_, v)->G.fromTuple
    let setC = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>, v: 'c): G.structure<'a, 'b, 'c, 'd, 'e, 'f> => s->G.toTuple->set3(_, v)->G.fromTuple
    let setD = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>, v: 'd): G.structure<'a, 'b, 'c, 'd, 'e, 'f> => s->G.toTuple->set4(_, v)->G.fromTuple
    let setE = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>, v: 'e): G.structure<'a, 'b, 'c, 'd, 'e, 'f> => s->G.toTuple->set5(_, v)->G.fromTuple
    let setF = (s: G.structure<'a, 'b, 'c, 'd, 'e, 'f>, v: 'f): G.structure<'a, 'b, 'c, 'd, 'e, 'f> => s->G.toTuple->set6(_, v)->G.fromTuple
  }

  module Make = (I: Interface, G: Generic, A: FieldTrip.Field, B: FieldTrip.Field, C: FieldTrip.Field, D: FieldTrip.Field, E: FieldTrip.Field, F: FieldTrip.Field) => {
    module Acc = Accessors(G)

    type input = G.structure<A.input, B.input, C.input, D.input, E.input, F.input>
    type inner = G.structure<A.t, B.t, C.t, D.t, E.t, F.t>
    type error = [#Whole(string) | #Part]
    type output = G.structure<A.output, B.output, C.output, D.output, E.output, F.output>
    type t = Store.t<inner, output, error>

    type validate = output => Js.Promise.t<Belt.Result.t<unit, string>>
    type context = {
      validate?: validate,
      inner: G.structure<A.context, B.context, C.context, D.context, E.context, F.context>,
    }

    type tupleinner = T.t<A.t, B.t, C.t, D.t, E.t, F.t>
    let tupleenum = T.make(A.enum, B.enum, C.enum, D.enum, E.enum, F.enum)
    let tupleinit = T.make(A.init, B.init, C.init, D.init, E.init, F.init)
    let tupleinput = T.make(A.input, B.input, C.input, D.input, E.input, F.input)
    let tupleresult = T.make(
      outputresult(A.output, A.enum),
      outputresult(B.output, B.enum),
      outputresult(C.output, C.enum),
      outputresult(D.output, D.enum),
      outputresult(E.output, E.enum),
      outputresult(F.output, F.enum),
    )
    let tuplePrintError = T.make(
      A.printError,
      B.printError,
      C.printError,
      D.printError,
      E.printError,
      F.printError,
    )
    let tupleShow = T.make(A.show, B.show, C.show, D.show, E.show, F.show)
    let tupleset = T.make(A.set, B.set, C.set, D.set, E.set, F.set)
    let tupleValidateImpl = T.make(
      A.validate,
      B.validate,
      C.validate,
      D.validate,
      E.validate,
      F.validate,
    )

    type allResult<'a, 'b, 'c, 'd, 'e, 'f, 'err> = tuple6<
      Result.t<'a, 'err>,
      Result.t<'b, 'err>,
      Result.t<'c, 'err>,
      Result.t<'d, 'err>,
      Result.t<'e, 'err>,
      Result.t<'f, 'err>,
    > => Result.t<tuple6<'a, 'b, 'c, 'd, 'e, 'f>, 'err>
    let allResult: allResult<'a, 'b, 'c, 'd, 'e, 'f, 'err> = x => {
      x->T.uncurry(Result.all6, _)->Result.map(T.encode)
    }

    let allPromise = x => {
      x->T.decode->Dynamic.combineLatest6->Dynamic.map(T.encode)
    }

    let set = (x: input) => x->G.toTuple->T.napply(tupleset)->G.fromTuple->Store.dirty

    let empty: context => inner = context =>
      context.inner->G.toTuple->T.napply(tupleinit)->G.fromTuple

    let init = context => context->empty->Store.init

    let prefer = (enum, make, inner, input) =>
      // First Prioritize Busy first if any children are busy
      Result.predicate(
        inner->T.mono(tupleenum)->Array.some(x => x == enum),
        make(input)->Dynamic.return,
        #Invalid,
      )

    let makeStore = (~context: context, ~force=false, inner: tupleinner): Dynamic.t<t> => {
      let innerP = G.fromTuple(inner)
      // TODO: These predicated values are computed up front
      // so these promises are made, and then thrown away
      // Should predicate take a thunk for lazy evaluation? - AxM
      [
        // First Prioritize Busy first if any children are busy
        prefer(#Busy, Store.busy, inner, innerP),
        // Then Prioritize Invalid state if any children are invalid
        prefer(#Invalid, Store.invalid(_, #Part), inner, innerP),
        // Otherwise take the first error we find
        T.napply(inner, tupleresult)
        ->allResult
        ->Result.map(out => {
          switch context.validate {
          | Some(validate) if I.validateImmediate || force =>
            validate(G.fromTuple(out))
            ->Dynamic.fromPromise
            ->Dynamic.map(
              Result.resolve(
                ~ok=_ => Store.valid(innerP, G.fromTuple(out)),
                ~err=e => Store.invalid(innerP, #Whole(e)),
              ),
            )
            ->Dynamic.startWith(Store.busy(innerP))
          // When we are given a validate function but not validateImmediate or force, do not assume valid until validated
          | Some(_validate) => Store.dirty(innerP)->Dynamic.return
          | _ => Store.valid(innerP, G.fromTuple(out))->Dynamic.return
          }
        }),
      ]
      ->Js.Array2.reduce(Result.first, Error(#Invalid))
      ->Result.resolve(~ok=x => x, ~err=resolveErr(innerP))
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      if !force && store->Store.toEnum == #Valid {
        store->Dynamic.return
      } else {
        tupleValidateImpl
        ->T.napply(T.return(force), _)
        ->T.napply(context.inner->G.toTuple, _)
        ->T.napply(store->Store.inner->G.toTuple, _)
        ->allPromise
        ->Dynamic.bind(makeStore(~context, ~force=true))
      }
    }

    type change = [
      | #Set(input)
      | #Clear
      | #A(A.change)
      | #B(B.change)
      | #C(C.change)
      | #D(D.change)
      | #E(E.change)
      | #F(F.change)
      | #Validate
    ]

    let tupleactions = T.make(
      a => #A(a),
      b => #B(b),
      c => #C(c),
      d => #D(d),
      e => #E(e),
      f => #F(f),
    )
    let actions: G.structure<
      A.change => change,
      B.change => change,
      C.change => change,
      D.change => change,
      E.change => change,
      F.change => change,
    > = G.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let inner = store->Dynamic.map(Store.inner)
      let innerT = inner->Dynamic.map(G.toTuple)

      let contextInner = context.inner->G.toTuple

      switch change {
      | #Set(input) =>
        input
        ->G.toTuple
        ->T.napply(tupleset)
        ->G.fromTuple
        ->Store.dirty
        ->(
          x => {
            if I.validateImmediate {
              validate(false, context, x)
            } else {
              Dynamic.return(x)
            }
          }
        )

      | #Clear => context->init->Dynamic.return
      | #A(ch) => {
          let get = get1
          let set = set1
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->A.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #B(ch) => {
          let get = get2
          let set = set2
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->B.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #C(ch) => {
          let get = get3
          let set = set3
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->C.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #D(ch) => {
          let get = get4
          let set = set4
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->D.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #E(ch) => {
          let get = get5
          let set = set5
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now
          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->E.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #F(ch) => {
          let get = get6
          let set = set6
          // These individual field setters return a different type based on the field
          // So some functor trickery to share this code.. not going to bother now

          let contextInner = contextInner->get
          innerT
          ->Dynamic.map(get)
          ->F.reduce(~context=contextInner, _, ch)
          ->Dynamic.withLatestFrom(store)
          // See Bind notes above
          ->Dynamic.bind(((a, store)) => {
            makeStore(~context, store->Store.inner->G.toTuple->set(a))
          })
        }

      | #Validate =>
        store
        ->Dynamic.take(1)
        ->Dynamic.bind(store => {
          validate(false, context, store)
        })
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      store->Store.inner->G.toTuple->T.napply(tupleinput)->G.fromTuple
    }

    let output = Store.output
    let error = Store.error
    let enum = Store.toEnum
    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(error => {
        switch error {
          | #Whole(error) => error->Some
          | #Part => store->Store.inner->G.toTuple->T.mono(tuplePrintError)->printErrorArray
        }
      })
    }


    let show = (store: t): string => {
      let (a, b, c, d, e, f) = store->inner->G.toTuple->T.napply(tupleShow)->T.decode
      `Product6{
        state: ${store->enum->Store.Enum.toPretty},
        error: ${store->printError->Option.getWithDefault("<none>")},
        children: {
          a: ${a},
          b: ${b},
          c: ${c},
          d: ${d},
          e: ${e},
          f: ${f},
        }
      }`
    }
  }
}
