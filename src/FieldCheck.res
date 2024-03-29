// shadow global Dynamic with the impl chosen by FT
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
): Dynamic.t<t> => {
  ignore(context)
  ignore(force)
  let inner = store->Store.inner
  Store.valid(inner, inner)
  ->Dynamic.return
}

type change = [#Set(input)]
let makeSet = input => #Set(input)
let showChange = (change: change) => {
  switch change {
  | #Set(input) => `Set(${input->string_of_bool})`
  }
}

type actions<'change> = { set: input => 'change }
let mapActions: (actions<'a>, 'a => 'b) => actions<'b> = (actions, fn) => {
  set: input => input->actions.set->fn
}
let actions: actions<change> = { 
  set: input => #Set(input)
}
  
type pack = Pack.t<t, change, actions<Promise.t<()>>, actions<()>>

let reduce = (
  ~context: context,
  store: Dynamic.t<t>,
  change: Indexed.t<change>,
): Dynamic.t<t> => {
  ignore(context)
  ignore(store)
  switch change.value {
  | #Set(val) => Store.valid(val, val)->Dynamic.return
  }
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
