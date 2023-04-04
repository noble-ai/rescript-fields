
type error = [#Empty | #TooShort| #External(string)]

type validate = string => Js.Promise.t<Belt.Result.t<string, error>>

type context = {
	validate?: validate,
}

let length = (~min: option<int>=?, ~max: option<int>=?, ()): validate => (str: string) => {
	switch str {
		| a if min->Option.mapWithDefault(false, min => a->Js.String2.length < min) => #TooShort->Belt.Result.Error
		| a if max->Option.mapWithDefault(false, max => a->Js.String2.length > max) => #TooShort->Belt.Result.Error
		| _ => Belt.Result.Ok(str)
	}->Promise.return
}

// Conveneincees for building context length
let min = x => Some(( Some(x), None))
let max = x => Some(( None, Some(x)))
let minmax = (min, max) => Some((Some(min), Some(max)))

type input = string
type output = string
type inner = string
type t = Store.t<inner, output, error>

module type IString = {
  let validateImmediate: bool
}

type change<'set> = [#Clear | #Reset | #Validate | #Set('set)]

module Make = (I: IString) => {
  type error = error
  type validate = validate
  type context = context
  type input = input
  type output = output
  type inner = inner
  type t = t

let empty = _ => ""
let init = context => context->empty->Store.init
// TODO: could return #Valid?
let set = Store.dirty

let validate = (
	force: bool,
	context: context,
	store: t,
): Dynamic.t<t> => {
	ignore(force)
	let _ = context // shut up unused warning

	// TODO: Should this be hanlded here or in Product - AxM
	switch store {
	| Init(input)
	| Dirty(input) =>
		// Does not avoid validation when already valid since +/- trvial
		switch input {
		| "" => Store.invalid(input, #Empty)->Dynamic.return
		| a =>
			switch context.validate {
			| None => Store.valid(a, a)->Dynamic.return
			| Some(validate) => {
					validate(a)
					->Rxjs.fromPromise
					->Dynamic.map(res => {
						switch res {
						| Ok(_) => Store.valid(a, a)
						| Error(err) => Store.invalid(a, err)
						}
					})
					->Dynamic.startWith(Store.busy(input))
				}
			}
		}
	| _ => Dynamic.return(store)
	}
}

type change = change<input>
let reduce = (
	~context: context,
	store: Dynamic.t<t>,
	change: change,
): Dynamic.t<t> => {
	switch change {
	| #Reset => init(context)->Dynamic.return
	| #Clear => init(context)->Dynamic.return
	| #Validate => {
		store
		->Dynamic.take(1)
		->Dynamic.bind((store) => Store.dirty(store->Store.inner)->validate(false, context, _))
	}
	| #Set(input) =>
      Store.dirty(input)->(
        x =>
          if I.validateImmediate {
            validate(false, context, x)
          } else {
            x->Dynamic.return
          }
      )
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
		state: ${store->enum->Store.Enum.toPretty},
	}`
}

let printError = (store: t) => {
	let error = store->Store.error
	switch error {
	| Some(#Empty) => Some("Empty")
	| Some(#TooShort) => Some("Too short")
	| _ => None
	}
}
}
