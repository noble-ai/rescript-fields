// shadow global Dynamic with the impl chosen by FT

type error = [#Empty | #TooShort | #TooLong | #External(string)]

type validate = string => Promise.t<Result.t<string, error>>

type context = {validate?: validate}

let length = (~min: option<int>=?, ~max: option<int>=?, ()): validate =>
  (str: string) => {
    switch str {
    | a if min->Option.map(min => a->String.length < min)->Option.or(false) =>
      #TooShort->Result.Error
    | a if max->Option.map(max => a->String.length > max)->Option.or(false) =>
      #TooLong->Result.Error
    | _ => Result.Ok(str)
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

type actions<'set> = {
  clear: () => change<'set>,
  reset: () => change<'set>, 
  validate: () => change<'set>,
  set: 'set => change<'set>,
}

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

  let validate = (force: bool, context: context, store: t): Dynamic.t<t> => {
    ignore(force)
    let _ = context // shut up unused warning

    // TODO: Should this be hanlded here or in Product - AxM
    switch store {
    | Init(input)
    | Dirty(input) =>
      switch context.validate {
      | None => Store.valid(input, input)->Dynamic.return
      | Some(validate) => validate(input)
        ->Rxjs.fromPromise
        ->Dynamic.map(res => {
          switch res {
          | Ok(_) => Store.valid(input, input)
          | Error(err) => Store.invalid(input, err)
          }
        })
        ->Dynamic.startWith(Store.busy(input))
      }
    | _ => Dynamic.return(store)
    }
  }

  type change = change<input>
  let makeSet = input => #Set(input)
  let showChange = (change: change) => {
    switch change {
    | #Clear => "Clear"
    | #Reset => "Reset"
    | #Validate => "Validate"
    | #Set(input) => `Set(${input->showInput})`
    }
  }

  type actions = actions<input>
  let actions = {
    clear: () => #Clear,
    reset: () => #Reset,
    validate: () => #Validate,
    set: input => #Set(input),
  }

  let reduce = (~context: context, store: Dynamic.t<t>, change: Indexed.t<change>): Dynamic.t<
    t,
  > => {
    switch change.value {
    | #Clear => init(context)->Dynamic.return
    | #Reset => init(context)->Dynamic.return
    | #Validate => store
      ->Dynamic.take(1)
      ->Rxjs.pipe(
        Rxjs.mergeMap(store => Store.dirty(store->Store.inner)->validate(false, context, _)),
      )
    | #Set(input) =>
      if I.validateImmediate {
        Store.dirty(input)->validate(false, context, _)
      } else {
        Store.dirty(input)->Dynamic.return
      }
    }
  }

  let enum = Store.toEnum
  let inner = Store.inner
  let input = Store.inner
  let output = Store.output
  let error = Store.error

  let show = (store: t) => {
    `FieldString{
		validateImmediate: ${I.validateImmediate ? "true" : "false"},
		state: ${store->enum->Store.enumToPretty},
	}`
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


