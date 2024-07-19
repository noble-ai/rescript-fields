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

type actions<'input, 'change> = {
  set: 'input => 'change,
  clear: unit => 'change,
  @ocaml.doc("Identity fields allow you to specify an empy value at the field and context level.
    In many places we have clearable inputs and want to allow this to reset the value.
    So instead of pattern matching on the change value, you can pass the optional value here as convenience.")
  opt: option<'input> => 'change,
}

// Make a module type for the functor to be able to connect types outward
module type FieldIdentity = (T: T) =>
  Field.T
    with type input = T.t
    and type output = T.t
    and type inner = T.t
    and type t = Store.t<T.t, T.t, unit>
    // and type change = setClear<T.t>
    and type context = contextEmpty<T.t>
    and type actions<'change> = actions<T.t, 'change>
    // and type pack = Form.t<
    //   Store.t<T.t, T.t, unit>,
    //   actions<T.t, ()>
    // >

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

  let validate = ( force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
    ignore(context)
    ignore(force)
    let input = store->Store.inner
    Store.Valid(input, input)->Dynamic.return
  }

  type actions<'change> = actions<input, 'change>

  let mapActions = (actions: actions<'change>, fn: 'change => 'b) => {
    set: input => input->actions.set->fn,
    clear: () => actions.clear()->fn,
    opt: i => i->actions.opt->fn,
  }

  let makeDyn = (context: context, setOuter: Rxjs.Observable.t<input>, val: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
    => {
    let field = init(context)

    let complete = Rxjs.Subject.makeEmpty()
    let setInner = Rxjs.Subject.makeEmpty()

    let clear = Rxjs.Subject.makeEmpty()
    let opt = Rxjs.Subject.makeEmpty()
    let actions: actions<unit> = {
      set: Rxjs.next(setInner),
      clear: Rxjs.next(clear),
      opt: Rxjs.next(opt),
    }

    let close = Rxjs.next(complete)

    let first: Close.t<Form.t<'f, 'a>> = {pack: {field, actions}, close}

    let clear = Rxjs.merge2(clear, opt->Dynamic.keepMap(Option.invert(_, ())))
          ->Dynamic.map(_ => init(context))

    let set = Rxjs.merge3(setOuter, setInner, opt->Dynamic.keepMap(x => x))
          ->Dynamic.map(x => x->set)

    let field = Rxjs.merge2( clear, set)
      //->Dynamic.log("FI field")

    let validated = 
      val
      ->Option.or(Rxjs.Subject.makeEmpty()->Rxjs.toObservable)
      ->Dynamic.withLatestFrom(field)
      ->Dynamic.map(Tuple.snd2)

    let dyn = 
      Rxjs.merge2(field, validated)
      ->Dynamic.map((field): Close.t<Form.t<'f, 'a>> => {pack: {field, actions}, close})
      ->Dynamic.map(Dynamic.return)
      ->Rxjs.pipe(Rxjs.takeUntil(complete))
 
    { first, dyn }
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
