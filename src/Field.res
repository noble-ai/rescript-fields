// Fields is a module for managing the update and validation of complex input.
// The singular Field module type describes the requirements for
// creating, modifying and validating an input
// Fields can be built that represent base level types values and inputs
// Fields can be built that compose other Fields, (producing a tree of Fields)
// allowing validation and change reduction at each level
// one change or possibly having affect on multiple children

// Each field is represented by a Field module that declares the storage, validation, and mutation of something.
// Some fields are defined as Module Functions/Functors so they can be composed.  FieldArray for example.

// The hope is that the basics will be nearly enough for small forms, but larger forms
// and validations will be more easily tested in vitro.

// TODO: debounced asyc validation
// TODO: graphql async validation based on hook provided function
// TODO: optimistic update chaging form twice?
// TODO: write tests for specific product fields. range etc.

// Its a little annyoing to switch against the Store.t enum to know what state we're in
// So provide an enum as convenience

// This module type describes the requirements for a Field module
// You'll see this Field in the Module Functions which asserts
// that a module passed to the function has each of these types and values.
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
  let validate: (bool, context, t ) => Dynamic.t<t>

  // Provide a type that specifies the changes you can make on this field.
  // So far this is a poly variant where some values may hold change types for children
  type change
  type actions
  let actions: actions

  // When a composite field is given a set change, we want to allow our children
  // to validate, but we do not have access [yet/ever] to their change action type
  // to send to their reduce function.  So instead, provide an explicit setValidate
  // that gives them context, and returns dynamic, like reduce would given a #Set - AxM
  // Not using named arguments so this is easier to use with napply patterns in Product2 etc
  let makeSet: input => change

  let showChange: change => string
  // Reduce takes definite store instead of optional, unlike Redux, to match React.useReducer
  // Reduce is async as a reduce may invoke a validation which is asychronous
  // TODO: Maybe better to have reduce produce more actions?
  let reduce: (
    ~context: context,
    Dynamic.t<t>,
    Indexed.t<change>,
  ) => Dynamic.t<t>

  // Accessors for input, output, etc via the Field

  // just return our children for digging
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