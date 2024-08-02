@@ocamldoc(" Store.t is the common shape of state for each Field.
 Each field will have a different instantaition of Store.t with different input, output, and error
 based on its children, etc.

 The Store.t can be in one of these five states
 It holds an 'input value in every state so we can maintain the state of inner fields
 as we transition between our states.
 When we are valid we provide an 'output value that is the result of the validation
 and when we are invalid we provide an error.
 ")

// Its a little annyoing to switch against the Store.t enum to know what state we're in
// So provide an enum as convenience
type enum = [#Init | #Dirty | #Busy | #Valid | #Invalid]

let enumToPretty = (e: enum) => {
  switch (e) {
    | #Init => "Init"
    | #Dirty => "Dirty"
    | #Busy => "Busy"
    | #Valid => "Valid"
    | #Invalid => "Invalid"
  }
}

let enumToA = (e: enum) => e->enumToPretty->String.toLowerCase

  @deriving(accessors)
  type t<'inner, 'output, 'error> =
    | Init('inner)
    | Dirty('inner)
    | Busy('inner)
    | Invalid('inner, 'error)
    | Valid('inner, 'output)
  // Validated and succeeded producing output

  let toEnum = (t: t<'i, 'o, 'e>): enum => {
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

  let bimap = (t: t<'i, 'o, 'e>, fni: 'i => 'ib, fno: 'o => 'ob) =>  {
    switch t {
      | Init(i) => Init(fni(i))
      | Dirty(i) => Dirty(fni(i))
      | Busy(i) => Busy(fni(i))
      | Valid(i, o) => Valid(fni(i), fno(o))
      | Invalid(i, e) => Invalid(fni(i), e)
    }
  }

  // Get output if one is available
  let output = (t: t<'i, 'o, 'e>) => {
    switch t {
    | Valid(_, output) => Some(output)
    | _ => None
    }
  }

  let mapOutput = (t, fn) => bimap(t, x => x, fn)

  // Get error if one is available
  let error = (t: t<'i, 'o, 'e>) => {
    switch t {
    | Invalid(_, error) => Some(error)
    | _ => None
    }
  }