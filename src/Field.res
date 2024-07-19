@@ocaml.doc("
This module type describes the requirements for a Field module
You'll see this Field.T in the Module Functions which asserts
that a module passed to the function has each of these types and values.
")

module type T = {
  // A field is passed a context to its validate and reduce methods
  // and it can be any shape of your choosing.
  // If you do not have any context you can use unit/()
  type context

  // For leaf fields this is the value provided to the input in question
  // for composite fields this will likely be a composition of their childrens inputs
  // but you have the ability to fix or map the contexts of your children if you need to
  type input
  let showInput: input => string

  // This is the type provided by a successful validation
  type output

  // This is the type provided by a failed validation
  type error

  // Give an inner type that is the true storage for this field
  // For leaf fields this is typically the same as input
  // for composite fields this will be a composition of Store.t for the children.
  type inner

  type t // Store.t<inner, output, error>

  // this is the default Store value for a field.
  let empty: context => inner
  let init: context => t

  // Provide a simple constructor for making a store from some initial input
  // Dont use this in dynamic situations like reduce - AxM
  let set: input => t

  // Provide a validate function that
  // given context and a Store.t for this field
  // produces a new Store.t asyncronously
  // Async added here as we do some network requests for password validations etc.
  // This force is to override the P.validateImmediate in Product2 etc, but might want a more narrow name
  // since we prob dont want to apply ALL async validations when this is true - AxM
  let validate: (bool, context, t ) => Rxjs.t<Rxjs.foreign, Rxjs.void, t>

  // Provide a type that specifies the changes you can make on this field.
  // So far this is a poly variant where some values may hold change types for children
  // type change
  // Every field has a record of functions producing changes at this level.
  // This type is opaque here so its a big of a hazard
  type actions<'change>
  let mapActions: (actions<'change>, 'change => 'b) => actions<'b>

  // Without any conctext, we have actions producing our own changes
  // let actions: actions<change>

  // @ocaml.doc("All fields have a pack so that the Pack decompsition system can go all the way to leaves, instead of running out just above in the last product/sum.")
  // type pack = Form.t<t, actions<()>>

  // When a composite field is given a set change, we want to allow our children
  // to validate, but we do not have access [yet/ever] to their change action type
  // to send to their reduce function.  So instead, provide an explicit setValidate
  // that gives them context, and returns dynamic, like reduce would given a #Set - AxM
  // Not using named arguments so this is easier to use with napply patterns in Product2 etc
  // let makeSet: input => change

  // let showChange: change => string
  
  // Each field wants to do its own validation when its set
  // So we want to take any set signal from a parent and pass down to children
  // So take in the set signal in makeDyn.

  // Returns an initial pack to expose actions to the parent
  // and allow the parent to prime observables with beginsWith etc.

  // Though most observables are static in as far as they know, Arrays do
  // create and destroy observables on the fly. When Array drops a channel
  // A new array is created and that last one is dropped by a switchMap
  // but in testing it seems that the observable never completes so we cant do testing
  // So provide a completion function along with each pack so we can close at any point.

  // NOTE: Chasing down closure of observable inputs is a paint, so implementations should use Rxjs.takeUntil 
  // to cut themselves off on a close event
  
  // takes an optional validation observable to enable decoration fields liek FieldOpt.
  // The system doesnt yet handle validation across all nodes of a field tree in the dyn situation.

  let makeDyn: (context, Rxjs.Observable.t<input>, option<Rxjs.Observable.t<()>>) => 
      Dyn.t<Close.t<Form.t<t, actions<()>>>>

  // let reduce: (
  //   ~context: context,
  //   Rxjs.t<Rxjs.foreign, Rxjs.void,t>,
  //   Indexed.t<change>,
  // ) => Rxjs.t<Rxjs.foreign, Rxjs.void,t>

  // Accessors for input, output, etc via the Field

  // just return our children for splitting
  let inner: t => inner

  // in leaf fields this is usually just return inner
  // in branch fields you will recursively reduce inner to input
  let input: t => input

  // Same as input but optional and for output type.
  // Since outputs are produced by validation, the composition is usually simpler
  let output: t => option<output>
  let error: t => option<error>
  let enum: t => Store.enum

  let show: t => string

  // If you want to print an error but dont want to traverse the tree
  let printError: t => option<string>
}

let printErrorArray = errors => {
  errors->Array.catOptions->Array.joinWith(", ")->Some
}

// TODO: Needs consolidation with changes - AxM
let setOrClear = v => v->Option.map(v => #Set(v))->Option.or(#Clear)
