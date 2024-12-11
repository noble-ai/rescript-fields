@@ocamldoc("A step up from FieldIdentity where the input type is string, and given an parse function, the remainder of the field opeerates on the type produced by parse")

module type Interface = {
  type t
  let parse: string => Result.t<t, string>
  let show: t => string
}

module Actions = {
  type t<'input, 'change> = {
    clear: unit => 'change,
    reset: unit => 'change,
    validate: unit => 'change,
    set: 'input => 'change,
  }

  let mapActions = (actions, fn) => {
    clear: () => fn(actions.clear()),
    reset: () => fn(actions.reset()),
    validate: () => fn(actions.validate()),
    set: input => fn(actions.set(input)),
  }
}

module Make = (I: Interface) => {
  type input = string
  type inner = string
  type output = I.t

  type error = string

  type t = Store.t<inner, output, error>

  type validate = I.t => Promise.t<Result.t<unit, error>>

  type context = {validate?: validate, validateImmediate?: bool}

  let logField = Dynamic.map(
    _,
    Dynamic.tap(_, (x: Close.t<Form.t<'t, 'a>>) => {
      Console.log2("FieldParse field", x.pack.field)
    }),
  )

  let showInput = (input: input) => `"${input}"`

  let empty = _ => ""
  let init = context => context->empty->Store.init

  // TODO: could return #Valid?
  let set = Store.dirty

  let validate = (force: bool, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void, t> => {
    // FIXME: needs to honor force flag?
    ignore(force)
    switch store {
    | Init(input)
    | Dirty(input) => {
      input
      ->I.parse
      ->Result.resolve(
        ~ok=value => {
          switch context.validate {
          | None => Store.valid(input, value)->Dynamic.return
          | Some(validate) => {
              value
              ->validate
              ->Promise.map(res => {
                switch res {
                | Ok(_) => Store.valid(input, value)
                | Error(err) => Store.invalid(input, err)
                }
              })
              ->Rxjs.fromPromise
              ->Dynamic.startWith(Store.busy(input))
            }
          }
        },
        ~err=err => Store.invalid(input, err)->Dynamic.return,
      )
    }
    | _ => Dynamic.return(store)
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
    `FieldParse {
  state: ${store->enum->Store.enumToPretty},
  input: ${store->input},
  output: ${store->output->Option.map(I.show)->Option.or("None")}
}`
  }

  let makeDyn = (
    context: context,
    initial: option<input>,
    setOuter: Rxjs.Observable.t<input>,
    valOuter: option<Rxjs.Observable.t<unit>>,
  ): Dyn.t<Close.t<Form.t<t, actions<unit>>>> => {
    let complete = Rxjs.Subject.makeEmpty()
    let clear = Rxjs.Subject.makeEmpty()
    let reset = Rxjs.Subject.makeEmpty()
    let setInner = Rxjs.Subject.makeEmpty()
    let valInner = Rxjs.Subject.makeEmpty()


    let actions: actions<unit> = {
      clear: Rxjs.next(clear),
      reset: Rxjs.next(reset),
      validate: Rxjs.next(valInner),
      set: x => Rxjs.next(setInner, x),
    }

    // For testing, you need to close EVERYTHING including the set to get the observable to close.
    // FIXME: can this be more aggressive? - AxM
    let close = Rxjs.next(complete)

    let field = 
      initial
      ->Option.map(set)
      ->Option.or(init(context))

    let first: Close.t<Form.t<'f, 'a>> = {pack: {field, actions}, close}
    let state = Rxjs.Subject.makeBehavior(first)

    let val = valOuter->Option.map(Rxjs.merge2(_, valInner))->Option.or(valInner->Rxjs.toObservable)

    let validateOpt =
      if context.validateImmediate->Option.or(true) {
        validate(false, context, _)
      } else {
        Dynamic.return
      }

    let resetted = reset->Dynamic.map(_ =>
      initial
      ->Option.map(set)
      ->Option.or(init(context))
      ->validateOpt
    )

    let cleared = clear->Dynamic.map(_ => {
      init(context)
      ->validateOpt
    })

    let val =
      val
      ->Dynamic.withLatestFrom(state)
      ->Dynamic.map(((_, state)) => state.pack.field->validate(true, context, _))

    let toClose = Dynamic.map(_, (field): Close.t<Form.t<t, 'b>> => {pack: {field, actions}, close})

    let init =
      field
      ->validateOpt
      ->toClose

    let setValidated =
        Rxjs.merge2(setOuter, setInner)
        ->Dynamic.map(input => {
          input->Store.dirty->validateOpt
        })

    let memoState = Dynamic.map(
      _,
      Dynamic.tap(_, (x: Close.t<Form.t<t, 'a>>) => {
        Rxjs.next(state, x)
      }),
    )

    let dyn =
      Rxjs.merge4(cleared, resetted, val, setValidated)
      // ->Dynamic.withLatestFrom(state)
      ->Dynamic.map(toClose)
      ->memoState
      ->Rxjs.pipe(Rxjs.takeUntil(complete))

    {first, init, dyn}
  }

  let printError = Store.error
}

module String = {
  module Field = Make({
    type t = string
    let parse = Result.ok
    external show: string => string = "%identity"
  })

  let length = (~min: option<int>=?, ~max: option<int>=?, ()): Field.validate =>
    (str: string) => {
      let x = ()
      switch str {
      | a if min->Option.map(min => a->String.length < min)->Option.or(false) =>
        "Too Short"->Result.Error
      | a if max->Option.map(max => a->String.length > max)->Option.or(false) =>
        "Too Long"->Result.Error
      | _ => Result.Ok()
      }->Promise.return
      ->Promise.delay(~ms=1000)
    }

  let contextNonEmpty: Field.context = {
    validate: length(~min=1, ()),
  }
}

module Float = Make({
  type t = float
  let parse = x => x->Prelude.Float.fromString->Result.fromOption("does not parse")
  let show = Float.toString
})

module OptFloat = Make({
  type t = option<float>
  let parse = (str: string) =>
    switch str {
    | "" => Ok(None)
    | str => 
        str
        ->Prelude.Float.fromString
        ->Result.fromOption("does not parse")
        ->Result.map(x => Some(x))
    }

  let show = (value: option<float>) =>
    switch value {
    | None => "None"
    | Some(value) => `Some(${Prelude.Float.toString(value)})`
    }
})

// let validateRangeFloat = (~min: option<float>=?, ~max: option<float>=?, ()): validate<float> => 
//   (value: Float.output) => {
//     switch value {
//     | a if min->Option.map(min => a < min)->Option.or(false) =>
//       `${a->Prelude.Float.toString} must be more than ${min
//         ->Option.getExn(~desc="min")
//         ->Prelude.Float.toString}`->Result.Error
//     | a if max->Option.map(max => a > max)->Option.or(false) =>
//       `${a->Prelude.Float.toString} must be less than ${max
//         ->Option.getExn(~desc="max")
//         ->Prelude.Float.toString}`->Result.Error
//     | _ => Result.Ok()
//     }->Promise.return
//   }

// let validatePercentageFloat: validate<Float.output> = 
//   (value: Float.output) => {
//     if value < 0.0 {
//       `${value->Prelude.Float.toString} must be more than 0% `->Result.Error
//     } else if value > 100.0 {
//       `${value->Prelude.Float.toString} must be less than 100% `->Result.Error
//     } else {
//       Result.Ok()
//     }->Promise.return
//   }

module Int = Make({
  type t = int
  let parse = x => x->Int.fromString->Result.fromOption("does not parse")
  let show = Int.toString
})

// let validateRangeInt = (~min: option<int>=?, ~max: option<int>=?, ()): validate<Int.output> =>
//   (value: Int.output) => {
//     switch value {
//     | a if min->Option.map(min => a < min)->Option.or(false) =>
//       `${a->PreludeInt.toString} must be more than ${min
//         ->Option.getExn(~desc="range min")
//         ->PreludeInt.toString}`->Result.Error
//     | a if max->Option.map(max => a > max)->Option.or(false) =>
//       `${a->PreludeInt.toString} must be less than ${max
//         ->Option.getExn(~desc="range max")
//         ->PreludeInt.toString}`->Result.Error
//     | _ => Result.Ok()
//     }->Promise.return
//   }

// let validateNonEmpty = (f: option<float>) => {
//   switch f {
//     | Some(f) => Ok((f->Some))
//     | None => Error("Value is required")
//     }
//   }->Promise.return

