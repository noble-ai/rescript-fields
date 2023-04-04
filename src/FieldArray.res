module Context = {
  type structure<'len, 'element> = {
    // External validation for array recieves output from all valid children
    // FieldArray does have this concept of filtering in IArray to consider, maybe we want to pass that last one in?
    // or just pass the Store and let it filter? -AxM
    // validate?: array<Element.structure<A.output, B.output, C.output> => Js.Promise.t<Belt.Result.t<unit, string>>,
    lengthMin: 'len,
    element: 'element,
  }
}

module type IArray = (F: FieldTrip.Field) =>
{
  let filter: array<F.t> => array<F.t>
  let empty: Context.structure<option<int>, F.context> => array<F.t>
}

let filterIdentity = (a: array<'a>) => a

let filterGrace = (a: array<'t>) => {
  a->Js.Array2.slice(~start=0, ~end_=a->Js.Array2.length - 1)
}

module Make = (I: IArray, F: FieldTrip.Field) => {
  module I = I(F)
  module Element = F
  type context = Context.structure<option<int>, Element.context>

  type input = array<Element.input>

  type output = array<Element.output>
  // TODO: this error type too much?
  type error = array<Element.t>
  type inner = array<Element.t>
  type t = Store.t<inner, output, error>

  let empty: context => inner = I.empty
  let init: context => t = context => context->empty->Store.init

  let set = (input: input): t => input->Js.Array2.map(F.set)->Dirty

  let makeOutput = (inner: inner): Result.t<array<F.output>, 'err> =>
    inner->Js.Array2.reduce((res, element) => {
      switch element->F.output {
      | Some(output) => res->Result.bind(res => Ok(Js.Array2.concat(res, [output])))
      | None => Error(element->F.enum)
      }
    }, Ok([]))

  let makeStore = (~context: context, inner: inner): t => {
    // Allow an array to be valid if it is totally valid or at least its significant elements
    // are valid, as chosen by by IArray filter
    // TODO: Move this all into the IArray policy?
    Result.first(makeOutput(inner), makeOutput(inner->I.filter))
    ->Result.guard(o => {
      context.lengthMin
      ->Option.map(lengthMin => o->Js.Array2.length >= lengthMin)
      ->Option.getWithDefault(true)
    }, #Invalid)
    ->Result.resolve(
      ~ok=output => Store.valid(inner, output),
      ~err=err => {
        switch err {
        | #Busy => Store.busy(inner)
        | _ => Store.invalid(inner, inner)
        }
      },
    )
  }

  let validate = (force, context: context, store: t): Dynamic.t<t> => {
    // Using combineLatest to get the status of all children
    // requires there be children. so add shortcut for empty array
    let inner = store->Store.inner
    if inner == [] {
      makeStore(~context, inner)->Dynamic.return
    } else {
      inner
      ->Js.Array2.map(Element.validate(force, context.element))
      ->Dynamic.combineLatest
      ->Dynamic.map(makeStore(~context))
    }
  }

  type change = [
    | #Set(input)
    | #Index(int, F.change)
    | #Add([#Some(F.input) | #Empty])
    | #Remove(int)
    | #Clear
  ]

  let reduce = (~context: context, store: Rxjs.t<'c, 's, t>, change: change): Rxjs.t<'c, 's, t> => {
    let contextElement = context.element

    switch change {
    | #Set(input) => {
      // When an array field is set, we don't know if the length
      // matches the previous length, or what relationship the elements
      // have to the previous, so drop everything, make a store, and validate
      // TODO: // F.set should honor validateImmediate flags
      input->Js.Array2.map(F.set)->makeStore(~context)->validate(false, context, _)
    }
    | #Index(index, change) =>
      F.reduce(
        ~context=contextElement,
        store->Dynamic.map(Store.inner)->Dynamic.map(Js.Array2.unsafe_get(_, index)),
        change,
      )
      ->Dynamic.withLatestFrom(store)
      ->Dynamic.map(((x, store)) =>
        store->Store.inner->Array.replace(x, index)->makeStore(~context)
      )
    | #Add(#Some(value)) =>
      store
      ->Dynamic.take(1)
      ->Dynamic.map((store: t) => {
        store->Store.inner->Js.Array2.concat([F.set(value)])->makeStore(~context)
      })
    | #Add(#Empty) =>
      store
      ->Dynamic.take(1)
      ->Dynamic.map((store: t) => {
        store->Store.inner->Js.Array2.concat([Element.init(contextElement)])->makeStore(~context)
      })
    | #Remove(i) =>
      store
      ->Dynamic.take(1)
      ->Dynamic.map((store: t) => store->Store.inner->Array.remove(i)->makeStore(~context))
    | #Clear => []->makeStore(~context)->Dynamic.return
    }
  }

  let inner = Store.inner

  let input = (store: t) => {
    store->Store.inner->Js.Array2.map(Element.input)
  }

  let error = Store.error

  let output = Store.output
  let enum = Store.toEnum

  let show = (store: t) => {
    `FieldArray{
      state: ${store->enum->Store.Enum.toPretty},
      children: [
        ${store->Store.inner->Js.Array2.map(Element.show)->Js.Array2.joinWith(",\n")}
      ]
    }`
  }

  let printError = (error: error) => {
    error
    ->Js.Array2.map(F.printError)
    ->Js.Array2.map(Option.getWithDefault(_, "None"))
    ->Js.Array2.mapi((a, i) => `${i->Belt.Int.toString}: ${a}`)
    ->Js.Array2.joinWith(", \n")
  }

  let printError = (s: t) => {
    s->Store.error->Option.map(printError)
  }
}
