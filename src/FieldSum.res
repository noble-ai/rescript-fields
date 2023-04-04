// prefer shadowing Dynamic
open FieldProduct

module Sum2 = {
  module Tuple = Product2.Tuple
  module T = Product2.T

  @deriving(accessors)
  type sum<'a, 'b> = A('a) | B('b)

  module type Interface = {
    // A variant type that has values of our own choosing
    type structure<'a, 'b>

    let fromGen: sum<'a, 'b> => structure<'a, 'b>
    let toGen: structure<'a, 'b> => sum<'a, 'b>
    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module Accessors = (I: Interface) => {
    let a = (s: I.structure<'a, 'b>) => {
      s->I.toGen->a
    }

    let setA = (_: I.structure<'a, 'b>, a: 'a) => {
      A(a)
    }

    let b = (s: I.structure<'a, 'b>) => {
      s->I.toGen->b
    }

    let setB = (_: I.structure<'a, 'b>, b: 'b) => {
      B(b)
    }
  }

  let makeStoreCtor = (a, inner, toOutput, toEnum, ctor, fromGen) =>
    [
      a
      ->toOutput
      ->Option.map(output => ctor(output)->fromGen->Store.valid(inner, _)->Dynamic.return),
      Option.predicate(a->toEnum == #Init, Store.init(inner)->Dynamic.return),
      Option.predicate(a->toEnum == #Invalid, Store.invalid(inner, #Part)->Dynamic.return),
    ]
    ->Js.Array2.reduce(Option.first, None)
    ->Option.getWithDefault(Store.dirty(inner)->Dynamic.return)

  //Sum needs Product for maintaining context
  // TODO: Rename as Make
  module Field = (S: Interface, P: Product2.Generic, A: FieldTrip.Field, B: FieldTrip.Field) => {
    include S

    module Acc = Accessors(S)
    module AccProd = Product2.Accessors(P)

    type input = S.structure<A.input, B.input>

    type context = {
      // When the product is valid, this validation is called allowing a check of all fields together
      // validate?: 
      //   S.structure<A.output, B.output> => Js.Promise.t<Belt.Result.t<unit, string>>,
      // ,
      empty?: input,
      inner: P.structure<A.context, B.context>,
    }

    type inner = S.structure<A.t, B.t>
    type error = [#Whole(string) | #Part]
    type output = S.structure<A.output, B.output>

    type t = Store.t<inner, output, error>

    // prefer a context given empty value over const A
    let empty = context =>
      context.empty->Option.mapWithDefault(S.fromGen(A(A.init(context.inner->AccProd.a))), init => {
        switch init->S.toGen {
        | A(a) => a->A.set->A->S.fromGen
        | B(b) => b->B.set->B->S.fromGen
        }
      })

    let init = context => context->empty->Store.init

    let set = (x: input): t => {
      // TODO: functor to map accessors? -AxM
      let g = x->S.toGen
      switch g {
      | A(a) => a->A.set->A->S.fromGen->Store.dirty
      | B(b) => b->B.set->B->S.fromGen->Store.dirty
      }
    }

    let makeStore = (a: sum<A.t, B.t>): Dynamic.t<t> => {
      let input = S.fromGen(a)
      switch a {
      // With no async validation we follow the children
      | A(a) => makeStoreCtor(a, input, A.output, A.enum, x => A(x), S.fromGen)
      | B(b) => makeStoreCtor(b, input, B.output, B.enum, x => B(x), S.fromGen)
      }
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      let input = store->Store.inner
      let gen = input->S.toGen
      let contextT = context.inner->P.toTuple
      switch gen {
      | A(a) => a->A.validate(force, contextT->Tuple.get1, _)->Dynamic.map(x => A(x))
      | B(b) => b->B.validate(force, contextT->Tuple.get2, _)->Dynamic.map(x => B(x))
      }->Dynamic.bind(makeStore)
    }

    type change = [#Clear | #Set(input) | #A(A.change) | #B(B.change) | #Validate]
    let tupleactions = Tuple.tuple2(a => #A(a), b => #B(b))
    let actions: P.structure<A.change => change, B.change => change> = P.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let input = store->Dynamic.map(s => s->Store.inner->S.toGen)
      switch change {
      | #Clear => context->init->Dynamic.return
      | #Set(input) => {
          let g = input->S.toGen
          switch g {
          | A(a) => A.set(a)->A
          | B(b) => B.set(b)->B
          }->makeStore
        }

      | #A(ch) => {
          // A submessage for A
          let contextA = context.inner->AccProd.a
          let inputA = input->Dynamic.map(i => {
            switch i {
            | A(a) => a
            | _ => A.init(contextA)
            }
          })
          A.reduce(~context=contextA, inputA, ch)
          ->Dynamic.map(x => A(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #B(ch) => {
          let contextB = context.inner->AccProd.b
          let inputB = input->Dynamic.map(i => {
            switch i {
            | B(a) => a
            | _ => B.init(contextB)
            }
          })
          B.reduce(~context=contextB, inputB, ch)
          ->Dynamic.map(x => B(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }
      | #Validate => {
        store
        ->Dynamic.take(1)
        ->Dynamic.bind( store => validate(true, context, store))
      }
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.input->A->S.fromGen
      | B(b) => b->B.input->B->S.fromGen
      }
    }

    let output = Store.output

    let error = Store.error
    let enum = Store.toEnum
    let show = (store: t): string => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.show
      | B(b) => b->B.show
      }
    }

    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(_error => {
        let g = store->Store.inner->S.toGen
        switch g {
        | A(a) => a->A.printError
        | B(b) => b->B.printError
        }
      })
    }
  }
}

module Sum3 = {
  module Tuple = Product3.Tuple
  module T = Product3.T

  @deriving(accessors)
  type sum<'a, 'b, 'c> = A('a) | B('b) | C('c)

  module type Interface = {
    // A variant type that has values of our own choosing
    //
    type structure<'a, 'b, 'c>

    // How do we map from our sum type to the generic A(x) | B(x) | C(x) type?
    let fromGen: sum<'a, 'b, 'c> => structure<'a, 'b, 'c>
    let toGen: structure<'a, 'b, 'c> => sum<'a, 'b, 'c>

    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module Accessors = (I: Interface) => {
    let a = (s: I.structure<'a, 'b, 'c>) => {
      s->I.toGen->a
    }

    let setA = (_: I.structure<'a, 'b, 'c>, a: 'a) => {
      A(a)
    }

    let b = (s: I.structure<'a, 'b, 'c>) => {
      s->I.toGen->b
    }

    let setB = (_: I.structure<'a, 'b, 'c>, b: 'b) => {
      B(b)
    }

    let c = (s: I.structure<'a, 'b, 'c>) => {
      s->I.toGen->c
    }

    let setC = (_: I.structure<'a, 'b, 'c>, c: 'c) => {
      C(c)
    }
  }

  //Sum needs Product for maintaining context
  module Field = (S: Interface, P: Product3.Generic, A: FieldTrip.Field, B: FieldTrip.Field, C: FieldTrip.Field) => {
    include S

    module Acc = Accessors(S)
    module AccProd = Product3.Accessors(P)

    type input = S.structure<A.input, B.input, C.input>
    type inner = S.structure<A.t, B.t, C.t>
    type output = S.structure<A.output, B.output, C.output>
    type error = [#Whole(string) | #Part]
    type t = Store.t<inner, output, error>

    type context = {
      // When the product is valid, this validation is called allowing a check of all fields together
      validate?: output => Js.Promise.t<Belt.Result.t<unit, string>>,
      empty?: input,
      inner: P.structure<A.context, B.context, C.context>,
    }

    let setInner = (init: input): inner => {
      switch init->S.toGen {
      | A(a) => a->A.set->A
      | B(b) => b->B.set->B
      | C(c) => c->C.set->C
      }->S.fromGen
    }

    // prefer a context given empty value over const A
    let empty = context =>
      context.empty->Option.mapWithDefault(S.fromGen(A(A.init(context.inner->AccProd.a))), setInner)

    let init = context => context->empty->Store.init

    let set = (x: input): t => x->setInner->Store.dirty

    let makeStore = (a: sum<A.t, B.t, C.t>): Dynamic.t<t> => {
      let input = S.fromGen(a)
      switch a {
      // With no async validation we follow the children
      | A(a) => Sum2.makeStoreCtor(a, input, A.output, A.enum, x => A(x), S.fromGen)
      | B(b) => Sum2.makeStoreCtor(b, input, B.output, B.enum, x => B(x), S.fromGen)
      | C(c) => Sum2.makeStoreCtor(c, input, C.output, C.enum, x => C(x), S.fromGen)
      }
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      let input = store->Store.inner
      let gen = input->S.toGen
      let contextT = context.inner->P.toTuple
      switch gen {
      | A(a) => a->A.validate(force, contextT->Tuple.get1, _)->Dynamic.map(x => A(x))
      | B(b) => b->B.validate(force, contextT->Tuple.get2, _)->Dynamic.map(x => B(x))
      | C(c) => c->C.validate(force, contextT->Tuple.get3, _)->Dynamic.map(x => C(x))
      }->Dynamic.bind(makeStore)
    }

    type change = [#Clear | #Set(input) | #A(A.change) | #B(B.change) | #C(C.change) | #Validate ]

    let tupleactions = T.make(a => #A(a), b => #B(b), c => #C(c))
    let actions: P.structure<
      A.change => change,
      B.change => change,
      C.change => change,
    > = P.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let input = store->Dynamic.map(Store.inner)
      switch change {
      | #Clear => context->init->Dynamic.return
      | #Set(input) => {
          let g = input->S.toGen
          switch g {
          | A(a) => A.set(a)->A
          | B(b) => B.set(b)->B
          | C(c) => C.set(c)->C
          }->makeStore
        }

      | #A(ch) => {
          // A submessage for A
          let contextA = context.inner->AccProd.a
          let inputA = input->Dynamic.map(i => {
            switch i->S.toGen {
            | A(a) => a
            | _ => A.init(contextA)
            }
          })
          A.reduce(~context=contextA, inputA, ch)
          ->Dynamic.map(x => A(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #B(ch) => {
          let contextB = context.inner->AccProd.b
          let inputB = input->Dynamic.map(i => {
            switch i->S.toGen {
            | B(a) => a
            | _ => B.init(contextB)
            }
          })
          B.reduce(~context=contextB, inputB, ch)
          ->Dynamic.map(x => B(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #C(ch) => {
          let contextC = context.inner->AccProd.c
          let inputC = input->Dynamic.map(i => {
            switch i->S.toGen {
            | C(a) => a
            | _ => C.init(contextC)
            }
          })
          C.reduce(~context=contextC, inputC, ch)
          ->Dynamic.map(x => C(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }
      | #Validate => {
        store
        ->Dynamic.take(1)
        ->Dynamic.bind( store => validate(true, context, store))
      }
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.input->A->S.fromGen
      | B(b) => b->B.input->B->S.fromGen
      | C(c) => c->C.input->C->S.fromGen
      }
    }

    let output = Store.output

    let error = Store.error
    let enum = Store.toEnum
    let show = (store: t): string => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.show
      | B(b) => b->B.show
      | C(c) => c->C.show
      }
    }

    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(_error => {
        let g = store->Store.inner->S.toGen
        switch g {
        | A(a) => a->A.printError
        | B(b) => b->B.printError
        | C(c) => c->C.printError
        }
      })
    }
  }
}

module Sum4 = {
  module Tuple = Product4.Tuple
  module T = Product4.T

  @deriving(accessors)
  type sum<'a, 'b, 'c, 'd> = A('a) | B('b) | C('c) | D('d)

  module type Interface = {
    // A variant type that has values of our own choosing
    //
    type structure<'a, 'b, 'c, 'd>

    // How do we map from our sum type to the generic A(x) | B(x) | C(x) | D(x) type?
    let fromGen: sum<'a, 'b, 'c, 'd> => structure<'a, 'b, 'c, 'd>
    let toGen: structure<'a, 'b, 'c, 'd> => sum<'a, 'b, 'c, 'd>

    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module Accessors = (I: Interface) => {
    let a = (s: I.structure<'a, 'b, 'c, 'd>) => {
      s->I.toGen->a
    }

    let setA = (_: I.structure<'a, 'b, 'c, 'd>, a: 'a) => {
      A(a)
    }

    let b = (s: I.structure<'a, 'b, 'c, 'd>) => {
      s->I.toGen->b
    }

    let setB = (_: I.structure<'a, 'b, 'c, 'd>, b: 'b) => {
      B(b)
    }

    let c = (s: I.structure<'a, 'b, 'c, 'd>) => {
      s->I.toGen->c
    }

    let setC = (_: I.structure<'a, 'b, 'c, 'd>, c: 'c) => {
      C(c)
    }

    let d = (s: I.structure<'a, 'b, 'c, 'd>) => {
      s->I.toGen->d
    }

    let setD = (_: I.structure<'a, 'b, 'c, 'd>, d: 'd) => {
      D(d)
    }
  }
  module Field = (S: Interface, P: Product4.Generic, A: FieldTrip.Field, B: FieldTrip.Field, C: FieldTrip.Field, D: FieldTrip.Field) => {
    include S

    module Acc = Accessors(S)
    module AccProd = Product4.Accessors(P)

    type context = {
      // When the product is valid, this validation is called allowing a check of all fields together
      // validate?: 
      //   S.structure<A.output, B.output, C.output, D.output> => Js.Promise.t<Belt.Result.t<unit, string>>,
      // ,
      empty?: S.structure<A.input, B.input, C.input, D.input>,
      inner: P.structure<A.context, B.context, C.context, D.context>,
    }

    type input = S.structure<A.input, B.input, C.input, D.input>
    type inner = S.structure<A.t, B.t, C.t, D.t>
    type output = S.structure<A.output, B.output, C.output, D.output>
    type error = [#Whole(string) | #Part]
    type t = Store.t<inner, output, error>

    // prefer a context given empty value over const A
    let empty = context =>
      context.empty->Option.mapWithDefault(S.fromGen(A(A.init(context.inner->AccProd.a))), init => {
        switch init->S.toGen {
        | A(a) => a->A.set->A->S.fromGen
        | B(b) => b->B.set->B->S.fromGen
        | C(c) => c->C.set->C->S.fromGen
        | D(d) => d->D.set->D->S.fromGen
        }
      })

    let init = context => context->empty->Store.init

    let set = (x: input): t => {
      // TODO: functor to map accessors? -AxM
      let g = x->S.toGen
      switch g {
      | A(a) => a->A.set->A->S.fromGen->Store.dirty
      | B(b) => b->B.set->B->S.fromGen->Store.dirty
      | C(c) => c->C.set->C->S.fromGen->Store.dirty
      | D(d) => d->D.set->D->S.fromGen->Store.dirty
      }
    }

    let makeStore = (a: sum<A.t, B.t, C.t, D.t>): Dynamic.t<t> => {
      let input = S.fromGen(a)
      switch a {
      // With no async validation we follow the children
      | A(a) => Sum2.makeStoreCtor(a, input, A.output, A.enum, x => A(x), S.fromGen)
      | B(b) => Sum2.makeStoreCtor(b, input, B.output, B.enum, x => B(x), S.fromGen)
      | C(c) => Sum2.makeStoreCtor(c, input, C.output, C.enum, x => C(x), S.fromGen)
      | D(d) => Sum2.makeStoreCtor(d, input, D.output, D.enum, x => D(x), S.fromGen)
      }
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      let input = store->Store.inner
      let gen = input->S.toGen
      let contextT = context.inner->P.toTuple
      switch gen {
      | A(a) => a->A.validate(force, contextT->Tuple.get1, _)->Dynamic.map(x => A(x))
      | B(b) => b->B.validate(force, contextT->Tuple.get2, _)->Dynamic.map(x => B(x))
      | C(c) => c->C.validate(force, contextT->Tuple.get3, _)->Dynamic.map(x => C(x))
      | D(d) => d->D.validate(force, contextT->Tuple.get4, _)->Dynamic.map(x => D(x))
      }->Dynamic.bind(makeStore)
    }

    type change = [#Clear | #Set(input) | #A(A.change) | #B(B.change) | #C(C.change) | #D(D.change) | #Validate]

    let tupleactions = T.make(a => #A(a), b => #B(b), c => #C(c), d => #D(d))
    let actions: P.structure<
      A.change => change,
      B.change => change,
      C.change => change,
      D.change => change,
    > = P.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let input = store->Dynamic.map(Store.inner)
      switch change {
      | #Clear => context->init->Dynamic.return
      | #Set(input) => {
          let g = input->S.toGen
          switch g {
          | A(a) => A.set(a)->A
          | B(b) => B.set(b)->B
          | C(c) => C.set(c)->C
          | D(d) => D.set(d)->D
          }->makeStore
        }

      | #A(ch) => {
          // A submessage for A
          let contextA = context.inner->AccProd.a
          let inputA = input->Dynamic.map(i => {
            switch i->S.toGen {
            | A(a) => a
            | _ => A.init(contextA)
            }
          })
          A.reduce(~context=contextA, inputA, ch)
          ->Dynamic.map(x => A(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #B(ch) => {
          let contextB = context.inner->AccProd.b
          let inputB = input->Dynamic.map(i => {
            switch i->S.toGen {
            | B(a) => a
            | _ => B.init(contextB)
            }
          })
          B.reduce(~context=contextB, inputB, ch)
          ->Dynamic.map(x => B(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #C(ch) => {
          let contextC = context.inner->AccProd.c
          let inputC = input->Dynamic.map(i => {
            switch i->S.toGen {
            | C(a) => a
            | _ => C.init(contextC)
            }
          })
          C.reduce(~context=contextC, inputC, ch)
          ->Dynamic.map(x => C(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #D(ch) => {
          let contextD = context.inner->AccProd.d
          let inputD = input->Dynamic.map(i => {
            switch i->S.toGen {
            | D(a) => a
            | _ => D.init(contextD)
            }
          })
          D.reduce(~context=contextD, inputD, ch)
          ->Dynamic.map(x => D(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }
      | #Validate => {
        store
        ->Dynamic.take(1)
        ->Dynamic.bind( store => validate(true, context, store))
      }
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.input->A->S.fromGen
      | B(b) => b->B.input->B->S.fromGen
      | C(c) => c->C.input->C->S.fromGen
      | D(d) => d->D.input->D->S.fromGen
      }
    }

    let output = Store.output

    let error = Store.error
    let enum = Store.toEnum

    let show = (store: t): string => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.show
      | B(b) => b->B.show
      | C(c) => c->C.show
      | D(d) => d->D.show
      }
    }
    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(_error => {
        let g = store->Store.inner->S.toGen
        switch g {
        | A(a) => a->A.printError
        | B(b) => b->B.printError
        | C(c) => c->C.printError
        | D(d) => d->D.printError
        }
      })
    }
  }
}
module Sum5 = {
  module Tuple = Product5.Tuple
  module T = Product5.T

  @deriving(accessors)
  type sum<'a, 'b, 'c, 'd, 'e> = A('a) | B('b) | C('c) | D('d) | E('e)

  module type Interface = {
    // A variant type that has values of our own choosing
    //
    type structure<'a, 'b, 'c, 'd, 'e>

    // How do we map from our sum type to the generic A(x) | B(x) | C(x) | D(x) | E(x) type?
    let fromGen: sum<'a, 'b, 'c, 'd, 'e> => structure<'a, 'b, 'c, 'd, 'e>
    let toGen: structure<'a, 'b, 'c, 'd, 'e> => sum<'a, 'b, 'c, 'd, 'e>

    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module Accessors = (I: Interface) => {
    let a = (s: I.structure<'a, 'b, 'c, 'd, 'e>) => {
      s->I.toGen->a
    }

    let setA = (_: I.structure<'a, 'b, 'c, 'd, 'e>, a: 'a) => {
      A(a)
    }

    let b = (s: I.structure<'a, 'b, 'c, 'd, 'e>) => {
      s->I.toGen->b
    }

    let setB = (_: I.structure<'a, 'b, 'c, 'd, 'e>, b: 'b) => {
      B(b)
    }

    let c = (s: I.structure<'a, 'b, 'c, 'd, 'e>) => {
      s->I.toGen->c
    }

    let setC = (_: I.structure<'a, 'b, 'c, 'd, 'e>, c: 'c) => {
      C(c)
    }

    let d = (s: I.structure<'a, 'b, 'c, 'd, 'e>) => {
      s->I.toGen->d
    }

    let setD = (_: I.structure<'a, 'b, 'c, 'd, 'e>, d: 'd) => {
      D(d)
    }

    let e = (s: I.structure<'a, 'b, 'c, 'd, 'e>) => {
      s->I.toGen->e
    }

    let setE = (_: I.structure<'a, 'b, 'c, 'd, 'e>, e: 'e) => {
      E(e)
    }
  }
  module Field = (
    S: Interface,
    P: Product5.Generic,
    A: FieldTrip.Field,
    B: FieldTrip.Field,
    C: FieldTrip.Field,
    D: FieldTrip.Field,
    E: FieldTrip.Field,
  ) => {
    include S

    module Acc = Accessors(S)
    module AccProd = Product5.Accessors(P)

    type context = {
      // When the product is valid, this validation is called allowing a check of all fields together
      // validate?: 
      //   S.structure<A.output, B.output, C.output, D.output> => Js.Promise.t<Belt.Result.t<unit, string>>,
      // ,
      empty?: S.structure<A.input, B.input, C.input, D.input, E.input>,
      inner: P.structure<A.context, B.context, C.context, D.context, E.context>,
    }

    type input = S.structure<A.input, B.input, C.input, D.input, E.input>
    type inner = S.structure<A.t, B.t, C.t, D.t, E.t>
    type output = S.structure<A.output, B.output, C.output, D.output, E.output>
    type error = [#Whole(string) | #Part]
    type t = Store.t<inner, output, error>

    // prefer a context given empty value over const A
    let empty = context =>
      context.empty->Option.mapWithDefault(S.fromGen(A(A.init(context.inner->AccProd.a))), init => {
        switch init->S.toGen {
        | A(a) => a->A.set->A->S.fromGen
        | B(b) => b->B.set->B->S.fromGen
        | C(c) => c->C.set->C->S.fromGen
        | D(d) => d->D.set->D->S.fromGen
        | E(e) => e->E.set->E->S.fromGen
        }
      })

    let init = context => context->empty->Store.init

    let set = (x: input): t => {
      // TODO: functor to map accessors? -AxM
      let g = x->S.toGen
      switch g {
      | A(a) => a->A.set->A->S.fromGen->Store.dirty
      | B(b) => b->B.set->B->S.fromGen->Store.dirty
      | C(c) => c->C.set->C->S.fromGen->Store.dirty
      | D(d) => d->D.set->D->S.fromGen->Store.dirty
      | E(e) => e->E.set->E->S.fromGen->Store.dirty
      }
    }

    let makeStore = (a: sum<A.t, B.t, C.t, D.t, E.t>): Dynamic.t<t> => {
      let input = S.fromGen(a)
      switch a {
      // With no async validation we follow the children
      | A(a) => Sum2.makeStoreCtor(a, input, A.output, A.enum, x => A(x), S.fromGen)
      | B(b) => Sum2.makeStoreCtor(b, input, B.output, B.enum, x => B(x), S.fromGen)
      | C(c) => Sum2.makeStoreCtor(c, input, C.output, C.enum, x => C(x), S.fromGen)
      | D(d) => Sum2.makeStoreCtor(d, input, D.output, D.enum, x => D(x), S.fromGen)
      | E(e) => Sum2.makeStoreCtor(e, input, E.output, E.enum, x => E(x), S.fromGen)
      }
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      let input = store->Store.inner
      let gen = input->S.toGen
      let contextT = context.inner->P.toTuple
      switch gen {
      | A(a) => a->A.validate(force, contextT->Tuple.get1, _)->Dynamic.map(x => A(x))
      | B(b) => b->B.validate(force, contextT->Tuple.get2, _)->Dynamic.map(x => B(x))
      | C(c) => c->C.validate(force, contextT->Tuple.get3, _)->Dynamic.map(x => C(x))
      | D(d) => d->D.validate(force, contextT->Tuple.get4, _)->Dynamic.map(x => D(x))
      | E(e) => e->E.validate(force, contextT->Tuple.get5, _)->Dynamic.map(x => E(x))
      }->Dynamic.bind(makeStore)
    }

    type change = [
      | #Clear
      | #Set(input)
      | #A(A.change)
      | #B(B.change)
      | #C(C.change)
      | #D(D.change)
      | #E(E.change)
      | #Validate
    ]

    let tupleactions = T.make(a => #A(a), b => #B(b), c => #C(c), d => #D(d), e => #E(e))
    let actions: P.structure<
      A.change => change,
      B.change => change,
      C.change => change,
      D.change => change,
      E.change => change,
    > = P.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let input = store->Dynamic.map(Store.inner)
      switch change {
      | #Clear => context->init->Dynamic.return
      | #Set(input) => {
          let g = input->S.toGen
          switch g {
          | A(a) => A.set(a)->A
          | B(b) => B.set(b)->B
          | C(c) => C.set(c)->C
          | D(d) => D.set(d)->D
          | E(e) => E.set(e)->E
          }->makeStore
        }

      | #A(ch) => {
          // A submessage for A
          let contextA = context.inner->AccProd.a
          let inputA = input->Dynamic.map(i => {
            switch i->S.toGen {
            | A(a) => a
            | _ => A.init(contextA)
            }
          })
          A.reduce(~context=contextA, inputA, ch)
          ->Dynamic.map(x => A(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #B(ch) => {
          let contextB = context.inner->AccProd.b
          let inputB = input->Dynamic.map(i => {
            switch i->S.toGen {
            | B(a) => a
            | _ => B.init(contextB)
            }
          })
          B.reduce(~context=contextB, inputB, ch)
          ->Dynamic.map(x => B(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #C(ch) => {
          let contextC = context.inner->AccProd.c
          let inputC = input->Dynamic.map(i => {
            switch i->S.toGen {
            | C(a) => a
            | _ => C.init(contextC)
            }
          })
          C.reduce(~context=contextC, inputC, ch)
          ->Dynamic.map(x => C(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #D(ch) => {
          let contextD = context.inner->AccProd.d
          let inputD = input->Dynamic.map(i => {
            switch i->S.toGen {
            | D(a) => a
            | _ => D.init(contextD)
            }
          })
          D.reduce(~context=contextD, inputD, ch)
          ->Dynamic.map(x => D(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }
      | #E(ch) => {
          let contextE = context.inner->AccProd.e
          let inputE = input->Dynamic.map(i => {
            switch i->S.toGen {
            | E(a) => a
            | _ => E.init(contextE)
            }
          })
          E.reduce(~context=contextE, inputE, ch)
          ->Dynamic.map(x => E(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }
      | #Validate => {
        store
        ->Dynamic.take(1)
        ->Dynamic.bind( store => validate(true, context, store))
      }
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.input->A->S.fromGen
      | B(b) => b->B.input->B->S.fromGen
      | C(c) => c->C.input->C->S.fromGen
      | D(d) => d->D.input->D->S.fromGen
      | E(e) => e->E.input->E->S.fromGen
      }
    }

    let output = Store.output

    let error = Store.error
    let enum = Store.toEnum

    let show = (store: t) => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.show
      | B(b) => b->B.show
      | C(c) => c->C.show
      | D(d) => d->D.show
      | E(e) => e->E.show
      }
    }

    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(_error => {
        let g = store->Store.inner->S.toGen
        switch g {
        | A(a) => a->A.printError
        | B(b) => b->B.printError
        | C(c) => c->C.printError
        | D(d) => d->D.printError
        | E(e) => e->E.printError
        }
      })
    }
  }
}

module Sum6 = {
  module Tuple = Product6.Tuple
  module T = Product6.T

  @deriving(accessors)
  type sum<'a, 'b, 'c, 'd, 'e, 'f> = A('a) | B('b) | C('c) | D('d) | E('e) | F('f)

  module type Interface = {
    // A variant type that has values of our own choosing
    //
    type structure<'a, 'b, 'c, 'd, 'e, 'f>

    // How do we map from our sum type to the generic A(x) | B(x) | C(x) | D(x) | E(x) type?
    let fromGen: sum<'a, 'b, 'c, 'd, 'e, 'f> => structure<'a, 'b, 'c, 'd, 'e, 'f>
    let toGen: structure<'a, 'b, 'c, 'd, 'e, 'f> => sum<'a, 'b, 'c, 'd, 'e, 'f>

    // Call async validate when both children become valid
    let validateImmediate: bool
  }

  module Accessors = (I: Interface) => {
    let a = (s: I.structure<'a, 'b, 'c, 'd, 'e, 'f>) => {
      s->I.toGen->a
    }

    let setA = (_: I.structure<'a, 'b, 'c, 'd, 'e, 'f>, a: 'a) => {
      A(a)
    }

    let b = (s: I.structure<'a, 'b, 'c, 'd, 'e, 'f>) => {
      s->I.toGen->b
    }

    let setB = (_: I.structure<'a, 'b, 'c, 'd, 'e, 'f>, b: 'b) => {
      B(b)
    }

    let c = (s: I.structure<'a, 'b, 'c, 'd, 'e, 'f>) => {
      s->I.toGen->c
    }

    let setC = (_: I.structure<'a, 'b, 'c, 'd, 'e, 'f>, c: 'c) => {
      C(c)
    }

    let d = (s: I.structure<'a, 'b, 'c, 'd, 'e, 'f>) => {
      s->I.toGen->d
    }

    let setD = (_: I.structure<'a, 'b, 'c, 'd, 'e, 'f>, d: 'd) => {
      D(d)
    }

    let e = (s: I.structure<'a, 'b, 'c, 'd, 'e, 'f>) => {
      s->I.toGen->e
    }

    let setE = (_: I.structure<'a, 'b, 'c, 'd, 'e, 'f>, e: 'e) => {
      E(e)
    }

    let f = (s: I.structure<'a, 'b, 'c, 'd, 'e, 'f>) => {
      s->I.toGen->f
    }

    let setF = (_: I.structure<'a, 'b, 'c, 'd, 'e, 'f>, f: 'f) => {
      F(f)
    }
  }
  module Field = (
    S: Interface,
    P: Product6.Generic,
    A: FieldTrip.Field,
    B: FieldTrip.Field,
    C: FieldTrip.Field,
    D: FieldTrip.Field,
    E: FieldTrip.Field,
    F: FieldTrip.Field,
  ) => {
    include S

    module Acc = Accessors(S)
    module AccProd = Product6.Accessors(P)

    type context = {
      // When the product is valid, this validation is called allowing a check of all fields together
      // validate: option<
      //   S.structure<A.output, B.output, C.output, D.output> => Js.Promise.t<Belt.Result.t<unit, string>>,
      // >,
      empty: option<S.structure<A.input, B.input, C.input, D.input, E.input, F.input>>,
      inner: P.structure<A.context, B.context, C.context, D.context, E.context, F.context>,
    }

    type input = S.structure<A.input, B.input, C.input, D.input, E.input, F.input>
    type inner = S.structure<A.t, B.t, C.t, D.t, E.t, F.t>
    type output = S.structure<A.output, B.output, C.output, D.output, E.output, F.output>
    type error = [#Whole(string) | #Part]
    type t = Store.t<inner, output, error>

    // prefer a context given empty value over const A
    let empty = context =>
      context.empty->Option.mapWithDefault(S.fromGen(A(A.init(context.inner->AccProd.a))), init => {
        switch init->S.toGen {
        | A(a) => a->A.set->A->S.fromGen
        | B(b) => b->B.set->B->S.fromGen
        | C(c) => c->C.set->C->S.fromGen
        | D(d) => d->D.set->D->S.fromGen
        | E(e) => e->E.set->E->S.fromGen
        | F(f) => f->F.set->F->S.fromGen
        }
      })

    let init = context => context->empty->Store.init

    let set = (x: input): t => {
      // TODO: functor to map accessors? -AxM
      let g = x->S.toGen
      switch g {
      | A(a) => a->A.set->A->S.fromGen->Store.dirty
      | B(b) => b->B.set->B->S.fromGen->Store.dirty
      | C(c) => c->C.set->C->S.fromGen->Store.dirty
      | D(d) => d->D.set->D->S.fromGen->Store.dirty
      | E(e) => e->E.set->E->S.fromGen->Store.dirty
      | F(f) => f->F.set->F->S.fromGen->Store.dirty
      }
    }

    let makeStore = (a: sum<A.t, B.t, C.t, D.t, E.t, F.t>): Dynamic.t<t> => {
      let input = S.fromGen(a)
      switch a {
      // With no async validation we follow the children
      | A(a) => Sum2.makeStoreCtor(a, input, A.output, A.enum, x => A(x), S.fromGen)
      | B(b) => Sum2.makeStoreCtor(b, input, B.output, B.enum, x => B(x), S.fromGen)
      | C(c) => Sum2.makeStoreCtor(c, input, C.output, C.enum, x => C(x), S.fromGen)
      | D(d) => Sum2.makeStoreCtor(d, input, D.output, D.enum, x => D(x), S.fromGen)
      | E(e) => Sum2.makeStoreCtor(e, input, E.output, E.enum, x => E(x), S.fromGen)
      | F(f) => Sum2.makeStoreCtor(f, input, F.output, F.enum, x => F(x), S.fromGen)
      }
    }

    let validate = (force, context: context, store: t): Dynamic.t<t> => {
      let input = store->Store.inner
      let gen = input->S.toGen
      let contextT = context.inner->P.toTuple
      switch gen {
      | A(a) => a->A.validate(force, contextT->Tuple.get1, _)->Dynamic.map(x => A(x))
      | B(b) => b->B.validate(force, contextT->Tuple.get2, _)->Dynamic.map(x => B(x))
      | C(c) => c->C.validate(force, contextT->Tuple.get3, _)->Dynamic.map(x => C(x))
      | D(d) => d->D.validate(force, contextT->Tuple.get4, _)->Dynamic.map(x => D(x))
      | E(e) => e->E.validate(force, contextT->Tuple.get5, _)->Dynamic.map(x => E(x))
      | F(f) => f->F.validate(force, contextT->Tuple.get6, _)->Dynamic.map(x => F(x))
      }->Dynamic.bind(makeStore)
    }

    type change = [
      | #Clear
      | #Set(input)
      | #A(A.change)
      | #B(B.change)
      | #C(C.change)
      | #D(D.change)
      | #E(E.change)
      | #F(F.change)
      | #Validate
    ]

    let tupleactions = T.make(a => #A(a), b => #B(b), c => #C(c), d => #D(d), e => #E(e), f => #F(f))
    let actions: P.structure<
      A.change => change,
      B.change => change,
      C.change => change,
      D.change => change,
      E.change => change,
      F.change => change,
    > = P.fromTuple(tupleactions)

    let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
      let input = store->Dynamic.map(Store.inner)
      switch change {
      | #Clear => context->init->Dynamic.return
      | #Set(input) => {
          let g = input->S.toGen
          switch g {
          | A(a) => A.set(a)->A
          | B(b) => B.set(b)->B
          | C(c) => C.set(c)->C
          | D(d) => D.set(d)->D
          | E(e) => E.set(e)->E
          | F(f) => F.set(f)->F
          }->makeStore
        }

      | #A(ch) => {
          // A submessage for A
          let contextA = context.inner->AccProd.a
          let inputA = input->Dynamic.map(i => {
            switch i->S.toGen {
            | A(a) => a
            | _ => A.init(contextA)
            }
          })
          A.reduce(~context=contextA, inputA, ch)
          ->Dynamic.map(x => A(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #B(ch) => {
          let contextB = context.inner->AccProd.b
          let inputB = input->Dynamic.map(i => {
            switch i->S.toGen {
            | B(a) => a
            | _ => B.init(contextB)
            }
          })
          B.reduce(~context=contextB, inputB, ch)
          ->Dynamic.map(x => B(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #C(ch) => {
          let contextC = context.inner->AccProd.c
          let inputC = input->Dynamic.map(i => {
            switch i->S.toGen {
            | C(a) => a
            | _ => C.init(contextC)
            }
          })
          C.reduce(~context=contextC, inputC, ch)
          ->Dynamic.map(x => C(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }

      | #D(ch) => {
          let contextD = context.inner->AccProd.d
          let inputD = input->Dynamic.map(i => {
            switch i->S.toGen {
            | D(a) => a
            | _ => D.init(contextD)
            }
          })
          D.reduce(~context=contextD, inputD, ch)
          ->Dynamic.map(x => D(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }
      | #E(ch) => {
          let contextE = context.inner->AccProd.e
          let inputE = input->Dynamic.map(i => {
            switch i->S.toGen {
            | E(a) => a
            | _ => E.init(contextE)
            }
          })
          E.reduce(~context=contextE, inputE, ch)
          ->Dynamic.map(x => E(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }
      | #F(ch) => {
          let contextF = context.inner->AccProd.f
          let inputF = input->Dynamic.map(i => {
            switch i->S.toGen {
            | F(a) => a
            | _ => F.init(contextF)
            }
          })
          F.reduce(~context=contextF, inputF, ch)
          ->Dynamic.map(x => F(x))
          // TODO: what bind
          // BUG: should use take(1) on store? - AxM
          ->Dynamic.bind(makeStore)
        }
      | #Validate => {
        store
        ->Dynamic.take(1)
        ->Dynamic.bind( store => validate(true, context, store))
      }
      }
    }

    let inner = Store.inner

    let input = (store: t) => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.input->A->S.fromGen
      | B(b) => b->B.input->B->S.fromGen
      | C(c) => c->C.input->C->S.fromGen
      | D(d) => d->D.input->D->S.fromGen
      | E(e) => e->E.input->E->S.fromGen
      | F(f) => f->F.input->F->S.fromGen
      }
    }

    let output = Store.output

    let error = Store.error
    let enum = Store.toEnum

    let show = (store: t) => {
      let g = store->Store.inner->S.toGen
      switch g {
      | A(a) => a->A.show
      | B(b) => b->B.show
      | C(c) => c->C.show
      | D(d) => d->D.show
      | E(e) => e->E.show
      | F(f) => f->F.show
      }
    }

    let printError = (store: t) => {
      store
      ->Store.error
      ->Option.bind(_error => {
        let g = store->Store.inner->S.toGen
        switch g {
        | A(a) => a->A.printError
        | B(b) => b->B.printError
        | C(c) => c->C.printError
        | D(d) => d->D.printError
        | E(e) => e->E.printError
        | F(f) => f->F.printError
        }
      })
    }
  }
}
