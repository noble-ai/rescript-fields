
// Allow a field to have Empty input
// But Require the value be set and valid for this to be valid
// So this output type is our the inner output type.
module Make = (F: FieldTrip.Field) => {
  type context = F.context

  type input = option<F.input>

  type inner = option<F.t>
  // Our validation requires our inner field be set
  type output = F.output
  // an error of an optional field can be either our concern for the value being specified
  // or the inner value being invalid
  type error = [#Whole(string) | #Part]

  type t = Store.t<inner, output, error>

  let empty = _ => None
  let init = context => context->empty->Store.init
  let set = (input: input): t => {
    input->Option.map(F.set)->Dirty
  }

  let makeStore = (inner: F.t): t => {
    [ inner->F.output->Option.map(output => Store.valid(Some(inner), output))
    , inner->F.error->Option.const(Store.invalid(Some(inner), #Part))
    , Option.predicate(inner->F.enum == #Busy, Store.busy(Some(inner)))
    , Option.predicate(inner->F.enum == #Dirty, Store.dirty(Some(inner)))
    , Option.predicate(inner->F.enum == #Init, Store.init(Some(inner)))
    ]->Js.Array2.reduce(Option.first, None)
    ->Option.getExn(~desc="makeStore")
  }

  let validate = (
    force,
    context: context,
    store: t,
  ): Dynamic.t<t> => {
    ignore(force)
    let input = store->Store.inner
    switch input {
    | None => Store.invalid(None, #Whole("Required"))->Dynamic.return
    | Some(val) => F.validate(false, context, val)->Dynamic.map(makeStore)
    }
  }

  type change = [#None | #Opt(option<F.change>) | #Some(F.change) | #Validate]
  let reduce = (
    ~context: context,
    store: Dynamic.t<t>,
    change: change,
  ): Dynamic.t<t> => {

    switch change {
    | #Opt(None)
    | #None => Store.dirty(None)->Dynamic.return
    | #Opt(Some(x))
    | #Some(x) => {
      let input = store->Dynamic.map( (store) => store->Store.inner->Option.getWithDefault(F.init(context)))

      F.reduce(~context, input, x)->Dynamic.map(makeStore)
    }
    // Todo check if child validated and submit valid - AxM
    | #Validate => {
      store
      ->Dynamic.take(1)
      // We are already taking only one store, so we can use an concatenative bind here
      ->Dynamic.bind( (store) => validate(false, context, store) )
    }
    }
  }

  let enum = Store.toEnum
  let inner = Store.inner
  let error = Store.error

  let input = (store: t) => {
    store->Store.inner->Option.map(F.input)
  }

  let output = (store: t): option<output> => {
    let inner = store->Store.inner
    inner->Option.bind(F.output)
  }

  let printError = (inner, error) =>
    switch error {
    | #Whole(str) => Some(str)
    | #Part => inner->Option.bind(F.printError)
    }

  let show = (store: t): string => {
    `FieldOpt{
      state: ${store->enum->Store.Enum.toPretty},
      inner: ${store->inner->Option.map(F.show)->Option.getWithDefault("None")},
    }`
  }
  let printError = (s: t) => {
    let inner = s->Store.inner
    s->Store.error->Option.bind(printError(inner, _))
  }
}

module Int = Make(FieldParse.Int)

module String = Make(FieldIdentity.String)

// Float inputs will have intermediate states that are valid or invalid floats
// causing controlled input to be difficult, so use FieldFloat instead of plain Identity.
module Float = Make(FieldParse.Float)

