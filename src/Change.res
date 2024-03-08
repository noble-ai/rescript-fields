type t<'a> = [#Set('a) | #Validate | #Reset | #Clear ]
let makeSet = x => #Set(x)

let show = (showInput, change) =>
  switch change {
  | #Set(input) => `Set(${input->showInput})`
  | #Reset => "Reset"
  | #Clear => "Clear"
  | #Validate => "Validate"
  }

type actions<'input, 'change> = {
  set: 'input => 'change,
  reset: unit => 'change,
  clear: unit => 'change,
  validate: unit => 'change,
}

let actions: actions<'a, t<'a>> = {
  set: makeSet,
  reset: () => #Reset,
  clear: () => #Clear,
  validate: () => #Validate,
}

let mapActions = (actions: actions<'a, 'out>, fn) => {
  set: x => actions.set(x)->fn,
  reset: _ => actions.reset()->fn,
  clear: _ => actions.clear()->fn,
  validate: _ => actions.validate()->fn,
}