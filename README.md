# Rescript Fields

Elaborate form validation for Rescript 

Fields is a module for managing the update and validation of complex input.
The singular `module type Field.T` describes the requirements for
creating, modifying and validating an input to produce either an output value or an error.
Using Rescript "Module Functors" Fields can be built that compose other Fields (producing a tree of Fields)
allowing validation and change reduction at each level. 
An attempt was made to implement common Fields and Field Patterns, and those are a large body of the library.
see FieldArray or FieldProduct.  
Each field is represented by a Field module that declares the storage, validation, and update of a value type.

## Installation

* Add `@nobleai/rescript-fields` to your project as you like
* Add `@nobleai/rescript-fields` to `bs-dev-dependencies`in bsconfig.json
* build `-with-deps`

## Provided Fields
* FieldIdentity
* FieldParse
* FieldArray 
* FieldSum (FieldEither)
* FieldProduct (FieldVector)
* FieldOpt

## Live example

For a runnable eversion try `yarn install; yarn rescript build; yarn run examples:everything`

## Login Form Example

```{rescript}

module FieldPassword = FieldParse.String.Field
module FieldUsername = FieldParse.String.Field

// Declare the structure of your desired output type
// This is outside of Generic to make accessors more easily available
@deriving(accessors)
type structure<'a, 'b> = {
  username: 'b,
  password: 'a,
}

// Give fields a map from your output type to a generic container (tuple)
module Generic = {
  type structure<'a, 'b> = structure<'a, 'b>

  let order = (password, username)
  let fromTuple = ((password, username)) => {username, password}
}

module Field = FieldProduct.Product2.Make(
  Generic,
  FieldUsername,
  FieldPassword,
)

let contextValidate: Field.context = {
  inner: {
    username: {validate: FieldParse.String.length(~min=2, ())},
    password: {validate: FieldParse.String.length(~min=6, ())},
  }
}

// Create a hook for running this field
module Form = UseField.Make(Field)

```


## TODO 
- debounced asyc validation  
- graphql async validation based on hook provided function  
- optimistic update chaging form twice?  
- Realign Polyvariant #A, #B, etc with sum 'a, 'b etc.


