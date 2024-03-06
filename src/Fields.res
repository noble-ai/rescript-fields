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

module Field = Field
module Store = Store 
module Array = FieldArray
module Check = FieldCheck
module Choice = FieldChoice
module Either = FieldEither
module Empty = FieldEmpty
module Identity = FieldIdentity
module Opt = FieldOpt
module Parse = FieldParse
module Product = FieldProduct
module String = FieldString
module Sum = FieldSum
module Vector = FieldVector
