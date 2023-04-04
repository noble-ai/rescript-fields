// FieldTrip is a module for managing the update and validation of complex input.
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
module Enum = {
	type t = [#Init | #Dirty | #Busy | #Valid | #Invalid]

	let toPretty = (e: t) => {
		switch (e) {
			| #Init => "Init"
			| #Dirty => "Dirty"
			| #Busy => "Busy"
			| #Valid => "Valid"
			| #Invalid => "Invalid"
		}
	}
}

// Store.t is the common shape of state for each Field.
// Each field will have a different instantaition of Store.t with different input, output, and error
// based on its children, etc.

// The Store.t can be in one of these five states
// It holds an 'input value in every state so we can maintain the state of inner fields
// as we transition between our states.
// When we are valid we provide an 'output value that is the result of the validation
// and when we are invalid we provide an error.

@deriving(accessors)
type t<'inner, 'output, 'error> =
	| Init('inner)
	| Dirty('inner)
	| Busy('inner)
	| Invalid('inner, 'error)
	| Valid('inner, 'output)
// Validated and succeeded producing output

let toEnum = (t: t<'i, 'o, 'e>): Enum.t => {
	switch t {
	| Init(_) => #Init
	| Dirty(_) => #Dirty
	| Busy(_) => #Busy
	| Valid(_, _) => #Valid
	| Invalid(_, _) => #Invalid
	}
}

// Get the input value regardless of state
let inner = (t: t<'i, 'o, 'e>) => {
	switch t {
	| Init(inner) =>inner
	| Dirty(inner) =>inner
	| Busy(inner) => inner
	| Valid(inner, _) =>inner
	| Invalid(inner, _) =>inner
	}
}

// Map the input producing a Store.t with a different input type
let mapInner = (t: t<'i, 'o, 'e>, fn: 'i => 'ib): t<'ib, 'o, 'e> => {
	t->inner->fn->Dirty
}

// Get output if one is available
let output = (t: t<'i, 'o, 'e>) => {
	switch t {
	| Valid(_, output) => Some(output)
	| _ => None
	}
}

// Get error if one is available
let error = (t: t<'i, 'o, 'e>) => {
	switch t {
	| Invalid(_, error) => Some(error)
	| _ => None
	}
}