// shadow global Dynamic with the impl chosen by FT

@@ocaml.doc("Here as a touchpoint for copypaste
  Explicitly typed as Field to force consistency with module type.
  but you shouldnt need to do that if youre implementing your own.
")

module Field: Field.T = {
  type context = unit
  type input = string
  let showInput = (input: input) => input
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
  let makeSet = input => input
  let showChange = (change: change) => change

  type actions<'change> = {
    set: input => 'change
  }

  let mapActions = (actions, fn) => {
    {set: x => x->actions.set->fn }
  }

  let actions: actions<change> = {
    set: x => x
  }

  let reduce = (~context, store: Dynamic.t<t>, _change: Indexed.t<'ch>): Dynamic.t<t> => {
    ignore(context)
    // Wrap store in index from change
    store
    // ->Dynamic.map( store => change->Indexed.map(_ => store))
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
