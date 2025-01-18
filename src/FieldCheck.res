type context = unit
type input = bool
let showInput = (input: input) => `${input->string_of_bool}`

type output = bool
type error = unit
type inner = bool
type t = Store.t<inner, output, error>

let empty = _ => false
let init = context => context->empty->Store.init

let set = input => Store.valid(input, input)

let validate = (
  force,
  context: context,
  store: t,
): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
  ignore(context)
  ignore(force)
  let inner = store->Store.inner
  Store.valid(inner, inner)
  ->Dynamic.return
}

type actions<'change> = { set: input => 'change }
let mapActions: (actions<'a>, 'a => 'b) => actions<'b> = (actions, fn) => {
  set: input => input->actions.set->fn
}

let makeDyn = (context: context, initial: option<Field.Init.t<input>>, setOuter: Rxjs.Observable.t<input>, _validate: option<Rxjs.Observable.t<()>> )
    : Dyn.t<Close.t<Form.t<t, actions<()>>>>
  => {
  let field =
    initial
    ->Option.map(x => x->Field.Init.get->set)
    ->Option.or(init(context))

  let complete = Rxjs.Subject.makeEmpty()
  let setInner = Rxjs.Subject.makeEmpty()

  let actions: actions<unit> = {
    set: Rxjs.next(setInner),
  }

  let close = Rxjs.next(complete)

  let first: Close.t<Form.t<'f, 'a>> = {pack: {field, actions}, close}

  let init = Dynamic.return(first)

  let dyn =
    Rxjs.merge2(setOuter, setInner)
    ->Dynamic.map(set)
    ->Dynamic.map((field): Close.t<Form.t<'f, 'a>> => {pack: {field, actions}, close})
    ->Dynamic.map(Dynamic.return)
    ->Rxjs.pipe(Rxjs.shareReplay(1))
    ->Rxjs.pipe(Rxjs.takeUntil(complete))

  { first, init, dyn }
}
  
let inner = Store.inner
let input = Store.inner
let output = Store.output
let error = Store.error
let enum = Store.toEnum

let show = (store: t) => {
  `FieldCheck{
    state: ${store->enum->Store.enumToPretty},
  }`
}

let printError = (store: t) => {
  ignore(store)
  None
}
