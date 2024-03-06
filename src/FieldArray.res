// shadow global Dynamic with the impl chosen by FT

module Context = {
  type structure<'output, 'element> = {
    // External validation for array recieves output from all valid children
    // FieldArray does have this concept of filtering in IArray to consider, maybe we want to pass that last one in?
    // or just pass the Store and let it filter? -AxM
    validate?: array<'output> => Promise.t<Result.t<unit, string>>,
    element: 'element,
  }
}

let length = (~len, arr) => {
  if arr->Array.length < len {
    Error("Must have at least " ++ string_of_int(len) ++ " elements")
  } else {
    Ok()
  }->Promise.return
}

module type IArray = (F: Field.T) =>
{
  let filter: array<F.t> => array<F.t>
  let empty: Context.structure<F.output, F.context> => array<F.t>
  let validateImmediate: bool
}

let filterIdentity = (a: array<'a>) => a

let filterGrace = (a: array<'t>) => {
  a->Array.slice(0, a->Array.length - 1)
}

module Make = (I: IArray, F: Field.T) => {
  module I = I(F)
  module Element = F
  type context = Context.structure<Element.output, Element.context>

  type input = array<Element.input>
  let showInput = (input: input) => {
    `[ ${input->Array.map(Element.showInput)->Array.joinWith(",\n")} ]`
  }

  type output = array<Element.output>
  type error = [#Whole(string) | #Part]
  type inner = array<Element.t>
  type t = Store.t<inner, output, error>

  let empty: context => inner = I.empty
  let init: context => t = context => context->empty->Store.init

  let set = (input: input): t => input->Array.map(F.set)->Dirty

  let makeOutput = (inner: inner): Result.t<array<F.output>, 'err> =>
    inner->Array.reduce((res, element) => {
      switch element->F.output {
      | Some(output) => res->Result.bind(res => Ok(Array.concat(res, [output])))
      | None => Error(element->F.enum)
      }
    }, Ok([]))

  let prefer = (enum, make, inner): Result.t<'a, 'e> =>
    // First Prioritize Busy first if any children are busy
    Result.predicate(
      inner->Array.map(Element.enum)->Array.some(x => x == enum),
      make(inner)->Dynamic.return,
      #Invalid,
    )

  let preferFiltered = (enum, make, inner, filtered): Result.t<'a, 'e> =>
    // First Prioritize Busy first if any children are busy
    Result.predicate(
      filtered->Array.map(Element.enum)->Array.some(x => x == enum),
      make(inner)->Dynamic.return,
      #Invalid,
    )

  let validateImpl = (context: context, force, inner) => {
    Result.first(makeOutput(inner), makeOutput(inner->I.filter))
    ->Result.mapError(_ => #Invalid)
    ->Result.map(out => {
      switch context.validate {
      | Some(validate) if I.validateImmediate || force =>
        validate(out)
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
    })
  }

  // Just like FieldProduct makeStore, but for an array of same elements
  let makeStore = (~context: context, ~force=false, inner: inner): Dynamic.t<t> => {
    [
      prefer(#Busy, Store.busy, inner),
      preferFiltered(#Invalid, Store.invalid(_, #Part), inner, inner->I.filter),
      preferFiltered(#Dirty, Store.dirty, inner, inner->I.filter),
      validateImpl(context, force, inner),
    ]
    ->Array.reduce(Result.first, Error(#Invalid))
    ->Result.resolve(~ok=x => x, ~err=FieldVector.resolveErr(inner))
  }

  let validate = (force, context: context, store: t): Dynamic.t<t> => {
    // Using combineLatest to get the status of all children
    // requires there be children. so add shortcut for empty array
    let inner = store->Store.inner
    if inner == [] {
      makeStore(~context, ~force, inner)
    } else {
      inner
      ->Array.map(Element.validate(force, context.element))
      ->Dynamic.combineLatest
      ->Dynamic.bind(makeStore(~context, ~force))
    }
  }

  type change = [
    | #Set(input)
    | #Index(int, F.change)
    | #Add([#Some(F.input) | #Empty])
    | #Remove(int)
    | #Clear
    | #Reset
  ]

  let makeSet = input => #Set(input)

  let showChange = (change: change) => {
    switch change {
    | #Set(input) => `Set(${showInput(input)})`
    | #Index(i, change) => `Index(${i->Int.toString}, ${Element.showChange(change)})`
    | #Add(#Empty) => `Add(#Empty)`
    | #Add(#Some(input)) => `Add(Some(${input->F.showInput}))`
    | #Remove(i) => `Remove(${i->Int.toString})`
    | #Reset => "Reset"
    | #Clear => `Clear`
    }
  }

  type actions = {
    set: input => change,
    index: (int, F.change) => change,
    add: [#Some(F.input) | #Empty] => change,
    remove: int => change,
    clear: change,
    reset: change,
  }

  let actions = {
    set: makeSet,
    index: (i, change) => #Index(i, change),
    add: input => #Add(input),
    remove: i => #Remove(i),
    clear: #Clear,
    reset: #Reset,
  }

  let enum = Store.toEnum
  let show = (store: t) => {
    `FieldArray{
      state: ${store->enum->Store.enumToPretty},
      children: [
        ${store->Store.inner->Array.map(Element.show)->Array.joinWith(",\n")}
      ]
    }`
  }

  let reduce = (~context: context, store: Rxjs.t<'c, 's, t>, change: Indexed.t<change>): Rxjs.t<'c, 's, t> => {
    switch change.value {
    | #Set(input) =>
       // When an array field is set, we don't know if the length
      // matches the previous length, or what relationship the elements
      // have to the previous, so drop everything, make a store, and validate
      // TODO: // F.set should honor validateImmediate flags
      // TODO: needs to go after last store.
      if input->Array.length > 0 {
        input
        ->Array.map(ch => (F.init(context.element)->Dynamic.return, ch->F.makeSet))
        ->Array.map( ((store, ch)) => F.reduce(~context=context.element, store, change->Indexed.map(_ => ch)))
        ->Dynamic.combineLatest
        ->Dynamic.bind(makeStore(~context))
      } else {
        []->makeStore(~context)
      }
    | #Index(index, ch) =>
      store
      ->Dynamic.map(Store.inner)
      ->Dynamic.map(Array.getUnsafe(_, index))
      ->F.reduce(~context=context.element, _, change->Indexed.map(_ => ch))
      ->Dynamic.withLatestFrom(store)
      ->Dynamic.bind(((x, store)) =>
        store->Store.inner->Array.replace(x, index)->makeStore(~context)
      )
    | #Add(#Some(value)) => {
      // StoreInner stays dynamic so we can pass later values to child to be applied to in their own makeStore
      let storeInner =
        store
        ->Dynamic.map(x => x->Store.inner)
        // ->Dynamic.log("storeInner")

      // We are taking the index once at the beginning so we do not drift off as the first update from the child will cause the length to grow
      storeInner
      ->Dynamic.map(Array.length)
      ->Dynamic.take(1)
      ->Dynamic.bind( index => {
        // get the store for the element, defaulting to F.init w context
        // Will not be set at first but will
        let storeElement =
          storeInner
          ->Dynamic.map( (arr) => arr->Array.get(index)->Option.or(F.init(context.element)))
          // ->Dynamic.log("storeElement")

        F.makeSet(value)
        ->Indexed.const(change, _)
        ->F.reduce(~context=context.element, storeElement, _)
        ->Dynamic.withLatestFrom(storeInner)
        ->Dynamic.bind(((x, storeInner)) =>
          storeInner
          ->Array.setUnsafe(index, x)
          ->makeStore(~context)
        )
      })
    }
    | #Add(#Empty) => {
      // StoreInner stays dynamic so we can pass later values to child to be applied to in their own makeStore
      let storeInner =
        store
        ->Dynamic.map(x => x->Store.inner)
        // ->Dynamic.log("storeInner")

      // We are taking the index once at the beginning so we do not drift off as the first update from the child will cause the length to grow
      storeInner
      ->Dynamic.map(Array.length)
      ->Dynamic.take(1)
      ->Dynamic.bind( index => {
        // get the store for the element, defaulting to F.init w context
        // Will not be set at first but will
        let storeElement =
          storeInner
          ->Dynamic.map( (arr) => arr->Array.get(index)->Option.or(F.init(context.element)))
          // ->Dynamic.log("storeElement")

        context.element
        ->F.init
        ->F.input
        ->F.makeSet
        ->Indexed.const(change, _)
        ->F.reduce(~context=context.element, storeElement, _)
        ->Dynamic.withLatestFrom(storeInner)
        ->Dynamic.bind(((x, storeInner)) =>
          storeInner
          ->Array.setUnsafe(index, x)
          ->makeStore(~context)
        )
      })
    }
    | #Remove(i) =>
      store
      ->Dynamic.take(1)
      ->Dynamic.bind((store: t) => store->Store.inner->Array.remove(i)->makeStore(~context))
    | #Clear => []->makeStore(~context)
    | #Reset => I.empty(context)->makeStore(~context)
    }
  }

  let inner = Store.inner

  let input = (store: t) => {
    store->Store.inner->Array.map(Element.input)
  }

  let error = Store.error

  let output = Store.output

  let printErrorInner = (inner: inner) => {
    inner
    ->Array.map(F.printError)
    ->Array.map(Option.or(_, "None"))
    ->Array.mapi((a, i) => `${i->Int.toString}: ${a}`)
    ->Array.joinWith(", \n")
  }

  let printError = (store: t) => {
    store
    ->Store.error
    ->Option.map(error => {
      switch error {
        | #Whole(_error) => _error
        | #Part => store->Store.inner->printErrorInner
      }
    })
  }
}
