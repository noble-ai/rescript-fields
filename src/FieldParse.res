// shadow global Dynamic with the impl chosen by FT

@@ocaml.doc("A Field for parsing string input into some more strict type t")

module type IParse = {
  type t
  let validateImmediate: bool
  let fromString: string => option<t>
  let show: t => string
}
  
type validate<'out> = 'out => Promise.t<Result.t<'out, string>>

type context<'validate, 'empty> = { 
  validate?: 'validate,
  empty?: 'empty
}
  
type change = [#Set(string) | #Clear | #Validate]

module Actions = {
  type t<'change> = {
    set: string => 'change,
    clear: () => 'change,
    validate: () => 'change,
  }

  let map = (actions, fn) => {
    set: x => x->actions.set->fn,
    clear: () => actions.clear()->fn,
    validate: () => actions.validate()->fn, 
  }

  let actions = {
    set: x => #Set(x),
    clear: () => #Clear,
    validate: () => #Validate,
  }
}
  
type error = [#DoesNotParse | #External(string)]

module type FieldParse = {
  include Field.T
}

module type Make = (I: IParse) => FieldParse
  with type input = string
  and type output = I.t
  and type context = context<validate<I.t>, string>
  and type t = Store.t<string, I.t, error>
  // and type change = change
  and type actions<'change> = Actions.t<'change>
  and type error = error
  and type inner = string

module Make: Make = (I: IParse) => {
  type input = string
  let showInput = x => x
  type output = I.t
  type error = error
  type inner = string

  type context = context<validate<output>, input>

  type t = Store.t<inner, output, error>

  let empty = _ => ""
  let init = context => context->empty->Store.Init

  // TODO: should return #Valid based on validateImmediate flag
  let set = Store.dirty

  let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
    ignore(context)
    ignore(force)
    let inner = store->Store.inner

    let val = I.fromString(inner)
    switch val {
    | Some(val) =>
      switch context.validate {
      | None => Store.valid(inner, val)->Dynamic.return
      | Some(validate) =>
        validate(val)
        ->Dynamic.fromPromise
        ->Dynamic.map(res => {
          switch res {
          | Ok(_) => Store.valid(inner, val)
          | Error(msg) => Store.invalid(inner, #External(msg))
          }
        })
        ->Dynamic.startWith(Store.busy(inner))
      }
    | None => Store.invalid(inner, #DoesNotParse)->Dynamic.return
    }
  }

  // type change = change
  // let makeSet = Actions.actions.set
  // let showChange = change =>
  //   switch change {
  //   | #Set(input) => `Set(${input})`
  //   | #Clear => "Clear"
  //   | #Validate => "Validate"
  //   }

  type actions<'change> = Actions.t<'change>
  let mapActions = Actions.map
  // let actions = Actions.actions

  let maybeValidate = (context, state)  =>
      if I.validateImmediate {
        validate(false, context, state)
      } else {
        state->Dynamic.return
      }

  let makeDyn = (context: context, setOuter: Rxjs.Observable.t<input>, valOuter: option<Rxjs.Observable.t<()>> )
      : Dyn.t<Close.t<Form.t<t, actions<()>>>>
    => {
    let field = init()

    let complete = Rxjs.Subject.makeEmpty()
    let close = Rxjs.next(complete)

    let state = Rxjs.Subject.makeBehavior(field)
    let setInner = Rxjs.Subject.makeEmpty()
    let clear = Rxjs.Subject.makeEmpty()
    let valInner = Rxjs.Subject.makeEmpty()

    let actions: actions<()> = {
      set: Rxjs.next(setInner),
      clear: Rxjs.next(clear),
      validate: Rxjs.next(valInner),
    }

    let first: Close.t<Form.t<'f, 'a>> = {pack: { field, actions }, close}
    
    let set = Rxjs.merge2(setOuter, setInner)
    let val = valOuter->Option.map(Rxjs.merge2(_, valInner))->Option.or(valInner->Rxjs.toObservable)

    let set = set->Dynamic.map(input => {
        input
        ->Store.dirty
        ->maybeValidate(context, _)
      })

    let clear = clear->Dynamic.map(_ => context->init->Dynamic.return)
       // ->maybeValidate(context, _)

    let validate = val 
      ->Dynamic.withLatestFrom(state)
      ->Dynamic.map(((_, field)) => validate(false, context, field))

    let changes = Rxjs.merge3(set, clear, validate) 
      changes 
      ->Dynamic.switchSequence
      ->Rxjs.subscribe_({
        next: (. field) => Rxjs.next(state, field),
        error: (. err) => Rxjs.error(state, err),
        complete: (. ) => Rxjs.complete(state)
      })

    let dyn = 
      changes 
      ->Dynamic.map((field) => 
        field
        // ->Dynamic.log("parse field")
        ->Dynamic.map( (field): Close.t<Form.t<t, 'b>> => {pack: {field, actions}, close})
      )
      ->Rxjs.toObservable
      ->Rxjs.pipe(Rxjs.takeUntil(complete))

    {first, dyn}
  }
 
  // let reduce = (~context: context, store: Rxjs.t<Rxjs.foreign, Rxjs.void,t>, change: Indexed.t<change>): Rxjs.t<Rxjs.foreign, Rxjs.void,
  //   t,
  // > => {
  //   ignore(context)
  //   switch change.value {
  //   | #Clear => context->init->Dynamic.return
  //   | #Set(input) =>
  //     input
  //     ->Store.dirty
  //     ->(
  //       x =>
  //         if I.validateImmediate {
  //           validate(false, context, x)
  //         } else {
  //           x->Dynamic.return
  //         }
  //     )

  //   // ->Dynamic.map(x => change->Indexed.map(_ => x))
  //   | #Validate =>
  //     store
  //     ->Dynamic.take(1)
  //     ->Dynamic.bind(store => {
  //       validate(false, context, store)
  //     })
  //   // ->Dynamic.map(x => change->Indexed.map(_ => x))
  //   }
  // }

  let enum = Store.toEnum
  let inner = Store.inner
  let input = Store.inner
  let output = Store.output
  let error = Store.error
  let show = (store: t) => {
    `FieldParse: {
      enum: ${store->Store.toEnum->Store.enumToPretty},
      input: "${store->input}",
      output: ${store
      ->output
      ->Option.map(I.show)
      ->Option.map(x => `Some(${x})`)
      ->Option.or("None")},
    }`
  }

  let printError = t =>
    t
    ->error
    ->Option.map(error =>
      switch error {
      | #Empty => "Cannot be empty"
      | #DoesNotParse => "Does not parse"
      | #External(msg) => msg
      }
    )
}

module PreludeFloat = Float
module Float = Make({
  type t = float
  let validateImmediate = true
  let fromString = Float.fromString
  let show = Float.toString
})

// An input with input type string, that we want to be valid if empty, but invalid if fails to parse
module OptFloat = Make({
  type t = option<float>
  let validateImmediate = true
  let fromString = (str: string) =>
    switch str {
    | "" => Some(None)
    | str => str->PreludeFloat.fromString->Option.map(x => Some(x))
    }

  let show = (value: option<float>) =>
    switch value {
    | None => "None"
    | Some(value) => `Some(${Prelude.Float.toString(value)})`
    }
})

let validateRangeFloat = (~min: option<float>=?, ~max: option<float>=?, ()): option<
  validate<float>,
> => Some(
  (value: Float.output) => {
    switch value {
    | a if min->Option.map(min => a < min)->Option.or(false) =>
      `${a->Prelude.Float.toString} must be more than ${min
        ->Option.getExn(~desc="min")
        ->Prelude.Float.toString}`->Result.Error
    | a if max->Option.map(max => a > max)->Option.or(false) =>
      `${a->Prelude.Float.toString} must be less than ${max
        ->Option.getExn(~desc="max")
        ->Prelude.Float.toString}`->Result.Error
    | _ => Result.Ok(value)
    }->Promise.return
  },
)

let validatePercentageFloat = (~value: option<float>=?): validate<Float.output> =>
  (value: Float.output) => {
    if value < 0.0 {
      `${value->Prelude.Float.toString} must be more than 0% `->Result.Error
    } else if value > 100.0 {
      `${value->Prelude.Float.toString} must be less than 100% `->Result.Error
    } else {
      Result.Ok(value)
    }->Promise.return
  }

module PreludeInt = Int

module Int = Make({
  type t = int
  let validateImmediate = true
  let fromString = Int.fromString
  let show = Int.toString
})

let validateRangeInt = (~min: option<int>=?, ~max: option<int>=?, ()): validate<Int.output> =>
  (value: Int.output) => {
    switch value {
    | a if min->Option.map(min => a < min)->Option.or(false) =>
      `${a->PreludeInt.toString} must be more than ${min
        ->Option.getExn(~desc="range min")
        ->PreludeInt.toString}`->Result.Error
    | a if max->Option.map(max => a > max)->Option.or(false) =>
      `${a->PreludeInt.toString} must be less than ${max
        ->Option.getExn(~desc="range max")
        ->PreludeInt.toString}`->Result.Error
    | _ => Result.Ok(value)
    }->Promise.return
  }

let validateNonEmpty = (f: option<float>) => {
  switch f {
    | Some(f) => Ok((f->Some))
    | None => Error("Value is required")
    }
  }->Promise.return
