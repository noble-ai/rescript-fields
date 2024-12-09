@@ocamldoc("FieldOpt is a field that allows optional input values.
This helps separate empty init from empty invalid states."
)

@deriving(accessors)
type actions<'clear, 'opt, 'inner, 'validate> = {
  clear: 'clear,
  opt: 'opt,
  inner: 'inner,
  validate: 'validate,
}

module type T = {
  include Field.T
  type parted
  let split: (Form.t<t, actions<()>>) => parted 
}

module type Make = (F: Field.T) => T
  with type t = Store.t<option<F.t>, F.output, [#Whole(string) | #Part]>
  and type context = F.context
  and type input = option<F.input>
  and type inner = option<F.t>
  and type output = F.output
  and type error = [#Whole(string) | #Part]
  and type actions<'change> = actions<
    () => 'change,
    option<F.input> => 'change,
    F.actions<'change>,
    () => 'change,
  >
  and type parted = option<Form.t<F.t, F.actions<()>>>

// Allow a field to have Empty input
// But Require the value be set and valid for this to be valid
// So this output type is our the inner output type.
module Make: Make = (F: Field.T) => {
  // module Inner = F
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

  // FieldOpt makeStore doesnt take validate like others
  // because the only goal of FieldOpt is to allow optional input values
  // notice that our context is the F.context so we have no specific validation behavior 
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

  let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
    ignore(force)
    let inner = store->Store.inner
    switch inner {
    | None => Store.invalid(None, #Whole("Required"))->Dynamic.return
    | Some(val) => F.validate(force, context, val)->Dynamic.map(makeStore)
    }
  }

  type actions<'change> = actions<
    () => 'change,
    option<F.input> => 'change,
    F.actions<'change>,
    () => 'change,
  >

  let mapActions = ({clear, opt, inner, validate}, fn) => {
    clear: () => clear()->fn,
    opt: x => x->opt->fn,
    inner: inner->F.mapActions(fn),
    validate: () => validate()->fn,
  }

  let applyClear = (clear, actions, close) => {
      clear
      ->Rxjs.pipe(Rxjs.map((_, _i) => Store.init(None)))
      ->Rxjs.pipe(Rxjs.map( (field, _): Close.t<Form.t<t, actions<()>>> => {pack:{ field, actions }, close}))
  }

  let applyInner = (inner: Rxjs.Observable.t<Close.t<Form.t<F.t, F.actions<()>>>>, actions, close) => {
      inner
      ->Dynamic.map(({pack}): Close.t<Form.t<t, actions<()>>> => {
        let field = pack.field->makeStore
        let actions = {
          ...actions,
          inner: pack.actions
        }
        {pack: { field, actions }, close}
      })
  }
  
  type parted = option<Form.t<F.t, F.actions<()>>>
  let split = (pack: Form.t<t, actions<()>>): option<Form.t<F.t, F.actions<()>>> => {
    pack.field
    ->Store.inner
    ->Option.map( (field): Form.t<F.t, F.actions<()>> => {
      field,
      actions: pack.actions.inner, 
    })
  }

  let makeDyn = (context: context, initial: option<input>, setOuter: Rxjs.Observable.t<input>, valOuter: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
    => {
    let complete = Rxjs.Subject.makeEmpty()
    let close = Rxjs.next(complete)

    let field =
      initial
      ->Option.map(set)
      ->Option.or(init(context))

    let clearInner: Rxjs.t<'c, Rxjs.source<()>, ()> =
        Rxjs.Subject.makeEmpty()

    let valInner = Rxjs.Subject.makeEmpty()
    let val = valOuter
      ->Option.map(Rxjs.merge2(_, valInner))
      ->Option.or(valInner->Rxjs.toObservable)

    let opt: Rxjs.t<'co, 'so, input> = Rxjs.Subject.makeEmpty()
    let setOpt = opt->Dynamic.keepMap(x => x)
    let clearOpt = opt->Dynamic.keepMap(Option.invert(_, ()))

    let (setOuter, clearOuter) =
      setOuter
      ->Dynamic.partition2((x=>x, Option.invert(_, ())))

    let clear = Rxjs.merge3(clearOuter, clearOpt, clearInner)

    let set = Rxjs.merge2(setOuter, setOpt)

    let initialInner = initial->Option.join
    let {first: firstInner, init: initInner, dyn: dynInner} = F.makeDyn(context, initialInner, set, Some(val))

    let actions: actions<()> = {
      clear: Rxjs.next(clearInner),
      opt: Rxjs.next(opt),
      inner: firstInner.pack->Form.actions,
      validate: Rxjs.next(valInner),
    }

    let first: Close.t<Form.t<t, actions<()>>> = {pack: {field, actions}, close}
    let init = initInner->applyInner(actions, close)

    let clear =
      clear
      ->applyClear(actions, close)
      ->Dynamic.map(Dynamic.return)

    let inner = dynInner->Dynamic.map(applyInner(_, actions, close))
    let changes = Rxjs.merge2( clear, inner )

    // Explicit validations need to take latest state, but we want the validation
    // async process to be interrupted by new state.
    // so maintain changes Observable-of-observable, and also
    // collapse changes to change here to use in validation
    let change = changes//->Dynamic.map(Dynamic.return)
      ->Dynamic.switchSequence

    // FIXME: needs a startsWith for withLatestFrom in case validate comes before change
    let validated = val
      ->Dynamic.withLatestFrom(change)
      ->Rxjs.toObservable
      ->Dynamic.map( ((_, {pack: {field, actions}, close})) =>
        validate(false, context, field)
        ->Dynamic.map((field): Close.t<Form.t<'f, 'a>> => {pack: {field, actions}, close})
      )

    let dyn =
      Rxjs.merge2(changes, validated)
      ->Rxjs.pipe(Rxjs.shareReplay(1))
      ->Rxjs.pipe(Rxjs.takeUntil(complete))

    {first, init, dyn}
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
