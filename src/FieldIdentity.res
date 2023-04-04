// T just says that a module provides a type t and an empty value
// used for common use of FieldIdentity
module type T = {
  type t
  let empty: t
}

// Bring record types out of fields so they are not hidden in functors, module type applications
type contextEmpty<'a> = {empty?: 'a}
type setClear<'a> = [#Clear | #Set('a)]

// Make a module type for the functor to be able to connect types outward
module type FieldIdentity = (T: T) =>
(
  FieldTrip.Field
    with type input = T.t
    and type output = T.t
    and type inner = T.t
    and type t = Store.t<T.t, T.t, unit>
    and type change = setClear<T.t>
    and type context = contextEmpty<T.t>
)

// FieldIdentity is the most basic field
// for any T primitive, make a field module that holds that value
// This is actually trouble for string inputs since
// it will override the user input in strange ways
// but useful for dropdowns
module Make: FieldIdentity = (T: T) => {
  module T = T
  type context = contextEmpty<T.t>
  type input = T.t
  type inner = T.t
  type output = T.t
  type error = unit

  type t = Store.t<inner, output, error>

  let empty = context => context.empty->Option.getWithDefault(T.empty)
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
  let reduce = (
    ~context: context,
    _store: Dynamic.t<t>,
    change: change,
  ): Dynamic.t<t> => {
    switch change {
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
    `FieldIdentity{ state: ${store->enum->Store.Enum.toPretty} }`
  }
  let printError = _error => None // No invalid states
}

module Unit = Make({
  type t = unit
  let empty = ()
})

module Bool = Make({
  type t = bool
  let empty = false
})

module Float = Make({
  type t = float
  let empty = 0.0
})

module Int = Make({
  type t = int
  let empty = 0
})

module String = Make({
  type t = string
  let empty = ""
})
