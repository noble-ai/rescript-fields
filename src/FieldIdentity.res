@@ocaml.doc("FieldIdentity is the most basic field
// for any T primitive, make a field module that holds that value
// This is actually trouble for string inputs since
// it will override the user input in strange ways
// but useful for dropdowns
")

// shadow global Dynamic with the impl chosen by FT

// T just says that a module provides a type t and an empty value
// used for common use of FieldIdentity
module type T = {
  type t
  let empty: t
  let show: t => string
}

// Bring record types out of fields so they are not hidden in functors, module type applications
type contextEmpty<'a> = {empty?: 'a}
type setClear<'a> = [#Clear | #Set('a)]

// Make a module type for the functor to be able to connect types outward
module type FieldIdentity = (T: T) =>
  Field.T
    with type input = T.t
    and type output = T.t
    and type inner = T.t
    and type t = Store.t<T.t, T.t, unit>
    and type change = setClear<T.t>
    and type context = contextEmpty<T.t>


module Make: FieldIdentity = (T: T) => {
  module T = T
  type context = contextEmpty<T.t>
  type input = T.t
  let showInput = T.show
  type inner = T.t
  type output = T.t
  type error = unit

  type t = Store.t<inner, output, error>

  let empty = context => context.empty->Option.or(T.empty)
  let init: context => t = context => context->empty->(x) => Store.Valid(x, x)

  let set = input => Store.Valid(input, input)

  let validate = (
    force,
    context: context,
    store: t,
  ): Dynamic.t<t> => {
    ignore(context)
    ignore(force)
    let input = store->Store.inner
    Store.Valid(input, input)->Dynamic.return
  }

  type change = setClear<T.t>
  let makeSet = inner => #Set(inner)

  let showChange = (change: change) => {
    switch change {
      | #Clear => "Clear"
      | #Set(x) => "Set(" ++ x->T.show ++ ")"
    }
  }

  type actions = {
    set: input => change,
    clear: unit => change,
  }
  let actions: actions = {
    set: input => #Set(input),
    clear: _ => #Clear,
  }

  let reduce = (
    ~context: context,
    _store: Dynamic.t<t>,
    change: Indexed.t<change>,
  ): Dynamic.t<t> => {
    switch change.value {
      | #Clear => context->init->Dynamic.return
      | #Set(val) => Store.Valid(val, val)->Dynamic.return
    }
  }

  let enum = Store.toEnum
  let inner = Store.inner
  let input = Store.inner
  let error = Store.error

  let output = Store.output
  let show = (store: t) => {
    `FieldIdentity{ state: ${store->enum->Store.enumToPretty}, value: ${store->input->T.show} }`
  }
  let printError = _error => None // No invalid states
}

module Unit = Make({
  type t = unit
  let empty = ()
  let show = _ => "()"
})

module Bool = Make({
  type t = bool
  let empty = false
  let show = (b: bool) => b ? "true" : "false"
})

module Float = Make({
  type t = float
  let empty = 0.0
  let show = Float.toString
})

module Int = Make({
  type t = int
  let empty = 0
  let show = Int.toString
})

module String = Make({
  type t = string
  let empty = ""
  let show = x => x
})

module OptString = Make({
  type t = option<string>
  let empty = None
  let show = x =>
    switch x {
      | None => "None"
      | Some(x) => "Some(" ++ x ++ ")"
    }
})
