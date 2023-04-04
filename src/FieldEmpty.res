
// Here as a touchpoint for copypaste
// Explicitly typed as Field to force consistency with module type.
// but you shouldnt need to do that if youre implementing your own.
module Field: FieldTrip.Field = {
  type context = unit
  type input = string
  type output = string
  type error = unit

  type inner = input
  type t = Store.t<inner, output, error>

  let empty: context => inner = _ => ""
  let init: context => t = context => context->empty->Store.init
  let set = Store.dirty

  let validate = (force, context, store: t) => {
    ignore(context)
    ignore(force)
    let inner = store->Store.inner
    Store.valid(inner, inner)->Dynamic.return
  }

  type change = input
  let reduce = (~context, store: Dynamic.t<t>, _change) => {
    ignore(context)
    store
  }

  // Inner is the immediate store values of children
  let inner = Store.inner

  let enum = Store.toEnum

  // Input is the projection of input value of all children.
  let input = Store.inner

  let output = Store.output
  let error = Store.error
  let show = (store: t) => {
    ignore(store)
    "Empty"
  }
  let printError = (_store: t) => {
    None
  }
}
