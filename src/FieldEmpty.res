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

  type actions<'change> = { set: input => 'change }
  let mapActions = (actions, fn) => {set: x => x->actions.set->fn }
  
  let makeDyn = (_context: context, _initial: option<input>, setOuter: Rxjs.t<'cs, 'ss, input>, val: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
    => {
    let setInner = Rxjs.Subject.makeEmpty()
    let complete = Rxjs.Subject.makeEmpty()
    let close = Rxjs.next(complete)

    let actions: actions<()> = {
      set: Rxjs.next(setInner)
    }

    let field = init()
    let first: Close.t<Form.t<t, actions<()>>> = {pack: { field, actions }, close}

    let val = val->Option.or(Rxjs.Subject.makeEmpty()->Rxjs.toObservable)

    let dyn = 
      Rxjs.merge2(
        setOuter->Dynamic.map(_ => field),
        val->Dynamic.map(_ => field)
      )
      ->Dynamic.map((field): Close.t<Form.t<t, actions<()>>> => {pack: { field, actions }, close})
      ->Rxjs.toObservable
      // Complete closes each particular event observable
      ->Rxjs.pipe(Rxjs.takeUntil(complete))
      ->Dynamic.map(Dynamic.return)
      // Complete closes the  observable of obserservables
      ->Rxjs.pipe(Rxjs.shareReplay(1))
      ->Rxjs.pipe(Rxjs.takeUntil(complete))

      { first, dyn }
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
