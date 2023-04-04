module type IParse = {
  type t
  let validateImmediate: bool
  let fromString: string => option<t>
}

module Make = (I: IParse) => {
  type input = string
  type output = I.t
  type error = [#DoesNotParse | #External(string)]
  type inner = string

  type validate = I.t => Js.Promise.t<Belt.Result.t<I.t, string>>
  type context = {validate?: validate, empty?: input}

  type t = Store.t<inner, output, error>

  let empty = _ => ""
  let init = context => context->empty->Store.Init

  // TODO: should return #Valid based on validateImmediate flag
  let set = Store.dirty

  let validate = (force, context: context, store: t): Dynamic.t<t> => {
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

  type change = [#Set(string) | #Clear | #Validate]
  let reduce = (~context: context, store: Dynamic.t<t>, change: change): Dynamic.t<t> => {
    ignore(context)
    switch change {
    | #Clear => context->init->Dynamic.return
    | #Set(input) =>
      input
      ->Store.dirty
      ->(
        x =>
          if I.validateImmediate {
            validate(false, context, x)
          } else {
            x->Dynamic.return
          }
      )

    | #Validate =>
      store
      ->Dynamic.take(1)
      ->Dynamic.bind(store => {
        validate(false, context, store)
      })
    }
  }

  let enum = Store.toEnum
  let inner = Store.inner
  let input = Store.inner
  let output = Store.output
  let error = Store.error
  let show = (store: t) => {
    ignore(store)
    `FieldParse: ${store->Store.toEnum->Store.Enum.toPretty} ${store->inner}`
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

module Float = Make({
  type t = float
  let validateImmediate = true
  let fromString = Belt.Float.fromString
})

// An input with input type string, that we want to be valid if empty, but invalid if fails to parse
module OptFloat = Make({
  type t = option<float>
  let validateImmediate = true
  let fromString = (str: string) =>
    switch str {
    | "" => Some(None)
    | str => str->Belt.Float.fromString->Option.map(x => Some(x))
    }
})

let validateRangeFloat = (~min: option<float>=?, ~max: option<float>=?, ()): option<
  Float.validate,
> => Some(
  (value: Float.output) => {
    switch value {
    | a if min->Option.mapWithDefault(false, min => a < min) =>
      `${a->Belt.Float.toString} must be more than ${min
        ->Option.getExn(~desc="min")
        ->Belt.Float.toString}`->Belt.Result.Error
    | a if max->Option.mapWithDefault(false, max => a > max) =>
      `${a->Belt.Float.toString} must be less than ${max
        ->Option.getExn(~desc="max")
        ->Belt.Float.toString}`->Belt.Result.Error
    | _ => Belt.Result.Ok(value)
    }->Promise.return
  },
)

module Int = Make({
  type t = int
  let validateImmediate = true
  let fromString = Belt.Int.fromString
})

let validateRangeInt = (~min: option<int>=?, ~max: option<int>=?, ()): Int.validate =>
  (value: Int.output) => {
    switch value {
    | a if min->Option.mapWithDefault(false, min => a < min) =>
      `${a->Belt.Int.toString} must be more than ${min
        ->Option.getExn(~desc="range min")
        ->Belt.Int.toString}`->Belt.Result.Error
    | a if max->Option.mapWithDefault(false, max => a > max) =>
      `${a->Belt.Int.toString} must be less than ${max
        ->Option.getExn(~desc="range max")
        ->Belt.Int.toString}`->Belt.Result.Error
    | _ => Belt.Result.Ok(value)
    }->Promise.return
  }
