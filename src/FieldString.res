// shadow global Dynamic with the impl chosen by FT

type error = [#Empty | #TooShort | #TooLong | #External(string)]

type validate = string => Promise.t<Result.t<(), error>>

type context = {validate?: validate}

let length = (~min: option<int>=?, ~max: option<int>=?, ()): validate =>
  (str: string) => {
    switch str {
    | a if min->Option.map(min => a->String.length < min)->Option.or(false) =>
      #TooShort->Result.Error
    | a if max->Option.map(max => a->String.length > max)->Option.or(false) =>
      #TooLong->Result.Error
    | _ => Result.Ok()
    }->Promise.return
  }

// Conveneincees for building context length
let min = x => Some((Some(x), None))
let max = x => Some((None, Some(x)))
let minmax = (min, max) => Some((Some(min), Some(max)))

type input = string

type output = string
type inner = string
type t = Store.t<inner, output, error>

module type IString = {
  let validateImmediate: bool
}

type change<'set> = [#Clear | #Reset | #Validate | #Set('set)]

module Actions = {
  type t<'input, 'change> = {
    clear: () => 'change,
    reset: () => 'change, 
    validate: () => 'change,
    set: 'input => 'change,
  }

  let mapActions = (actions, fn) => {
    clear: () => fn(actions.clear()),
    reset: () => fn(actions.reset()),
    validate: () => fn(actions.validate()),
    set: input => fn(actions.set(input)),
  }

  let actions = {
    clear: () => #Clear,
    reset: () => #Reset,
    validate: () => #Validate,
    set: input => #Set(input),
  }
}
  
type actions<'change> = Actions.t<input, 'change>
type pack = Form.t<t, actions<()>>

module Make = (I: IString) => {
  type error = error
  type validate = validate
  type context = context
  type input = input

  type output = output
  type inner = inner
  type t = t

  let showInput = (input: input) => `"${input}"`

  let empty = _ => ""
  let init = context => context->empty->Store.init

  // TODO: could return #Valid?
  let set = Store.dirty

  let validate = (force: bool, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
    ignore(force)
    // let _ = context // shut up unused warning

    // Console.log2("String validate", store->Store.toEnum)
    // TODO: Should this be hanlded here or in Product - AxM
    switch store {
    | Init(input)
    | Dirty(input) =>
      switch context.validate {
      | None => Store.valid(input, input)->Dynamic.return
      | Some(validate) => {
        validate(input)
        ->Promise.map(res => {
          // Console.log(`FieldString validate "${input}"`)
          switch res {
          | Ok(_) => Store.valid(input, input)
          | Error(err) => Store.invalid(input, err)
          }
        })
        ->Rxjs.fromPromise
        ->Dynamic.startWith(Store.busy(input))
      }
      }
    | _ => Dynamic.return(store)
    }
  }

  type change = change<input>
  // let makeSet = input => #Set(input)
  let showChange = (change: change) => {
    switch change {
    | #Clear => "Clear"
    | #Reset => "Reset"
    | #Validate => "Validate"
    | #Set(input) => `Set(${input->showInput})`
    }
  }

  type actions<'change> = Actions.t<input, 'change>
  let mapActions = Actions.mapActions

  let enum = Store.toEnum
  let inner = Store.inner
  let input = Store.inner
  let output = Store.output
  let error = Store.error

  let show = (store: t) => {
    `FieldString{
		validateImmediate: ${I.validateImmediate ? "true" : "false"},
		state: ${store->enum->Store.enumToPretty},
    input: ${store->input},
    output: ${store->output->Option.or("None")}
	}`
  }


  let makeDyn = (context: context, setOuter: Rxjs.Observable.t<input>, valOuter: option<Rxjs.Observable.t<()>>)
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
    => {
    let field = init(context)

    let complete = Rxjs.Subject.makeEmpty()
    let clear = Rxjs.Subject.makeEmpty()
    let reset = Rxjs.Subject.makeEmpty()
    let setInner = Rxjs.Subject.makeEmpty()
    let valInner = Rxjs.Subject.makeEmpty()

    let set = Rxjs.merge2(setOuter, setInner)

    let state = Rxjs.Subject.makeBehavior(field)

    let actions: actions<()> = {
      clear: Rxjs.next(clear),
      reset: Rxjs.next(reset),
      validate: Rxjs.next(valInner),
      set: Rxjs.next(setInner)
    }

    // For testing, you need to close EVERYTHING including the set to get the observable to close.
    // FIXME: can this be more aggressive? - AxM
    let close = Rxjs.next(complete)

    let first: Close.t<Form.t<'f, 'a>> = {pack: {field, actions}, close}

    let val = 
          valOuter
          ->Option.map(Rxjs.merge2(_, valInner))
          ->Option.or(valInner->Rxjs.toObservable)

    let clear =
          clear
          ->Dynamic.map(_ => if I.validateImmediate {
              init(context)->validate(false, context, _)
            } else {
              init(context)->Dynamic.return
            }
          ) 

    let reset = 
          reset
          ->Dynamic.map(_ => init(context)->Dynamic.return)

    let val = 
          val 
          ->Dynamic.withLatestFrom(state)
          ->Dynamic.map(((_, state)) => state->validate(true, context, _))
    
    let set = set
      ->Dynamic.map(input => {
          if I.validateImmediate {
            Store.dirty(input)->validate(false, context, _)
          } else {
            Store.dirty(input)->Dynamic.return
          }
        })
      
    let memoState = Dynamic.map(_, Dynamic.tap(_, (x: Close.t<Form.t<t, 'a>>) => {
      // Console.log2("FieldString memoState", x.pack.field)
      Rxjs.next(state, x.pack.field)
    }))

    let logField = Dynamic.map(_, Dynamic.tap(_, (x: Close.t<Form.t<t, 'a>>) => {
      Console.log2("FieldString field", x.pack.field)
    }))

    let dyn = 
      Rxjs.merge4(clear, reset, val, set)
      ->Dynamic.map(Dynamic.map(_, (field): Close.t<Form.t<t, 'b>> => {pack: {field, actions}, close}))
      ->Dynamic.startWith(Dynamic.return(first))
      ->memoState
      ->Rxjs.pipe(Rxjs.takeUntil(complete))
      // ->logField

    {first, dyn}
  }

  let printError = (store: t) => {
    let error = store->Store.error
    switch error {
    | Some(#Empty) => Some("Empty")
    | Some(#TooShort) => Some("Too short")
    | Some(#TooLong) => Some("Too Long")
		| Some(#External(msg)) => Some(msg)
    | None => None
    }
  }
}

let contextNonEmpty: context = {
  validate: length(~min=1, ())
}


