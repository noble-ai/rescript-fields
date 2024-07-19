()
// // shadow global Dynamic with the impl chosen by FT
// open FieldIdentity

// // FIXME: not a valid field
// module Make = (T: T) => {
//   type context = array<T.t>
//   type input = T.t
//   type output = T.t
//   type error = unit
//   type inner = T.t
//   type t = Store.t<inner, output, error>

//   let empty = context => context->Array.getUnsafe(0)
//   let init = (context: context) => context->empty->Store.Init

//   // TODO: should return #Valid based on a validateImmediate flag - AxM
//   let set = input => Store.Dirty(input)

//   let validate = (
//     ~force=false,
//     context,
//     store: t,
//   ): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
//     ignore(context)
//     ignore(force)
//     let input = store->Store.inner
//     Store.Valid(input, input)->Dynamic.return
//   }

//   type change = T.t

//   type pack = Form.t<t, change, actions<Promise.t<()>>, actions<()>>

//   let reduce = (
//     ~context: context,
//     _store: t,
//     change: Indexed.t<change>,
//   ): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
//     ignore(context)
//     Store.Valid(change.value, change.value)->Dynamic.return
//   }

//   let enum = Store.toEnum
//   let inner = Store.inner
//   let input = Store.inner
//   let error = Store.error

//   let output = Store.output

//   let printError = _error => None // No invalid states
// }

