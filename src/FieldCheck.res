
type context = unit
type input = bool
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
let reduce = (
  ~context: context,
  store: Dynamic.t<t>,
  change: change,
): Dynamic.t<t> => {
  ignore(context)
  ignore(store)
  switch change {
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
    state: ${store->enum->Store.Enum.toPretty},
  }`
}

let printError = (store: t) => {
  ignore(store)
  None
}
