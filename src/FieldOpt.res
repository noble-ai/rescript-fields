// shadow global Dynamic with the impl chosen by FT

// Allow a field to have Empty input
// But Require the value be set and valid for this to be valid
// So this output type is our the inner output type.
module Make = (F: Field.T) => {
  module Inner = F
  type context = F.context

  type input = option<F.input>
  let showInput = (input: input): string =>
    switch input {
    | Some(x) => `Some(${F.showInput(x)})`
    | None => "None"
    }

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

  let makeStorePred = (inner, enum, ctor) =>
    inner->F.enum == enum ? ctor(Some(inner))->Some : None

  let makeStore = (inner: F.t): t => {
    [
      inner->F.output->Option.map(output => Store.valid(Some(inner), output)),
      inner->F.error->Option.const(Store.invalid(Some(inner), #Part)),
      makeStorePred(inner, #Busy, Store.busy),
      makeStorePred(inner, #Dirty, Store.dirty),
      makeStorePred(inner, #Init, Store.init),
    ]
    ->Array.reduce(Option.first, None)
    ->Option.getExn(~desc="makeStore")
  }

  let validate = (force, context: context, store: t): Dynamic.t<t> => {
    ignore(force)
    let input = store->Store.inner
    switch input {
    | None => Store.invalid(None, #Whole("Required"))->Dynamic.return
    | Some(val) => F.validate(false, context, val)->Dynamic.map(makeStore)
    }
  }

  type change = [#None | #Opt(option<F.change>) | #Some(F.change) | #Validate]
  let makeSet = (inner: input): change  => inner->Option.map(F.makeSet)->#Opt

  let showChange = (change: change): string =>
    switch change {
    | #None => "None"
    | #Opt(None) => "Opt(None)"
    | #Opt(Some(x)) => `Opt(Some(${F.showChange(x)}))`
    | #Some(x) => `Some(${F.showChange(x)})`
    | #Validate => "Validate"
    }

  type actions<'change> = {
    none: () => 'change,
    opt: (option<F.change>) => 'change,
    some: (F.change) => 'change,
    validate: () => 'change,
  }

  let mapActions = ({none, opt, some, validate}, fn) => {
    none: () => none()->fn,
    opt: x => x->opt->fn,
    some: x => x->some->fn,
    validate: () => validate()->fn,
  }

  let actions: actions<change> = {
    none: () => #None,
    opt: x => #Opt(x),
    some: x => #Some(x),
    validate: () => #Validate,
  }

  let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<t> => {
    switch change.value {
    | #Opt(None)
    | #None =>
      Store.dirty(None)->Dynamic.return
    | #Opt(Some(x))
    | #Some(x) => {
        let input =
          store->Dynamic.map(store => store->Store.inner->Option.or(F.init(context)))
        F.reduce(~context, input, change->Indexed.map( _ => x))->Dynamic.map(makeStore)
      }
    // Todo check if child validated and submit valid - AxM
    | #Validate => store
      ->Dynamic.take(1)
      // We are already taking only one store, so we can use an concatenative bind here
      ->Dynamic.bind(store => validate(false, context, store))
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
      state: ${store->enum->Store.enumToPretty},
      inner: ${store->inner->Option.map(F.show)->Option.or("None")},
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
