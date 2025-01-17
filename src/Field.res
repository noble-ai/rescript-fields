@@ocaml.doc("
This module type describes the requirements for a Field module
You'll see this Field.T in the Module Functions which asserts
that a module passed to the function has each of these types and values.
")

module Init = {
  @deriving(accessors)
  type t<'a> = Validate('a) | Natural('a)
  let map = (t, fn) => {
    switch t {
    | Validate(a) => Validate(fn(a))
    | Natural(a) => Natural(fn(a))
    }
  }

  let get = t => {
    switch t {
    | Validate(a) => a
    | Natural(a) => a
    }
  }

  let toValidate = (t: t<'a>) => {
    switch t {
    | Validate(a) => Some(a)
    | Natural(_) => None
    }
  }

  let isValidate  = t => t->toValidate->Option.isSome

  let toNatural = (t: t<'a>) => {
    switch t {
      | Validate(_) => None
      | Natural(a) => Some(a)
    }
  }

  let toNatural = t => t->toNatural->Option.isSome

  let collectOption = (t: t<'a>, fn: 'a => option<'b>): option<t<'b>> => {
    switch t {
      | Validate(a) => fn(a)->Option.map(validate)
      | Natural(a) => fn(a)->Option.map(natural)
    }
  }

  let distributeOption = collectOption(_, x=>x)

  let collectArray = (t: t<'a>, fn: 'a => array<'b>): array<t<'b>> => {
    switch t {
      | Validate(a) => fn(a)->Array.map(validate)
      | Natural(a) => fn(a)->Array.map(natural)
    }
  }

  let distributeArray = collectArray(_, x=>x)
}

module type T = {
  @ocamldoc("A field is passed a context to its validate and reduce methods
  and it can be any shape of your choosing.
  If you do not have any context you can use unit/()
  ")
  type context

  @ocamldoc(" For leaf fields this is the value provided to the input in question
   for composite fields this will likely be a composition of their childrens inputs
   but you have the ability to fix or map the contexts of your children if you need to
  ")
  type input
  let showInput: input => string

  @ocamldoc("his is the type produces by a successful validation")
  type output

  @ocamldoc("This is the type provided by a failed validation")
  type error

  @ocamldoc("Give an inner type that is the true storage for this field
  For leaf fields this is typically the same as input
  for composite fields this will be a composition of Store.t for the children.
  ")
  type inner

  @ocamldoc("This is the persisted state of the field. Usually Store.t<inner, output, error>")
  type t

  @ocamldoc("this is the default Store value for a field.")
  let empty: context => inner
  let init: context => t

  @ocamldoc(" Provide a simple constructor for making a store from some initial input
  Dont use this in dynamic situations like reduce - AxM
  ") 
  let set: input => t

  @ocamldoc("Provide a validate function that
  given context and a Store.t for this field
  produces a new Store.t asyncronously
  Async added here as we do some network requests for password validations etc.
  This force is to override the P.validateImmediate in Product2 etc, but might want a more narrow name
  since we prob dont want to apply ALL async validations when this is true - AxM
  ")
  let validate: (bool, context, t ) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>

  @ocamldoc("Provide a type that specifies the changes you can make on this field.
  So far this is a poly variant where some values may hold change types for children
  Every field has a record of functions producing changes at this level.
  This type is opaque here so its a big of a hazard
  ")
  type actions<'change>
  let mapActions: (actions<'change>, 'change => 'b) => actions<'b>

  @ocamldoc("Each field wants to do its own validation when its set
  So we want to take any set signal from a parent and pass down to children
  So take in the set signal in makeDyn.

  Returns an initial pack to expose actions to the parent
  and allow the parent to prime observables with beginsWith etc.

  Though most observables are static in as far as they know, Arrays do
  create and destroy observables on the fly. When Array drops a channel
  A new array is created and that last one is dropped by a switchMap
  but in testing it seems that the observable never completes so we cant do testing
  So provide a completion function along with each pack so we can close at any point.

  NOTE: Chasing down closure of observable inputs is a paint, so implementations should use Rxjs.takeUntil 
  to cut themselves off on a close event
  
  takes an optional validation observable to enable decoration fields liek FieldOpt.
  The system doesnt yet handle validation across all nodes of a field tree in the dyn situation.

  takes an optional input to initialize the state of the field.
  This is should be passed to any children but only reflected in the first value.
  Either/Sum use the emission from Dyn as a signal that the sum state has changed
  So were all inits to emit to dyn, the Sums will be confused.
  There may be cases where you _DO_ want to emit to dyn, like adding an element to FieldArray, but
  needs to be handled in Array - AxM
  ")
  let makeDyn: (context, option<Init.t<input>>, Rxjs.Observable.t<input>, option<Rxjs.Observable.t<()>>) =>
      Dyn.t<Close.t<Form.t<t, actions<()>>>>

  // Accessors for input, output, etc via the Field

  @ocamldoc("just return our children for splitting")
  let inner: t => inner

  @ocamldoc("in leaf fields this is usually just return inner
  in branch fields you will recursively reduce inner to input
  ")
  let input: t => input

  @ocamldoc("Same as input but optional and for output type.
    Since outputs are produced by validation, the composition is usually simpler
  ")
  let output: t => option<output>
  let error: t => option<error>
  let enum: t => Store.enum

  let show: t => string

  @ocamldoc("If you want to print an error but dont want to traverse the tree")
  let printError: t => option<string>
}

let printErrorArray = errors => {
  errors->Array.catOptions->Array.joinWith(", ")->Some
}