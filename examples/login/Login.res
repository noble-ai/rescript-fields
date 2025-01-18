module FieldPassword = FieldParse.String.Field
module FieldUsername = FieldParse.String.Field

module InputString = {
  // Render a single input controlled by the form
  @react.component
  let make = (~label, ~form: Fields.Form.t<FieldParse.String.Field.t, FieldParse.String.Field.actions<()>>) => {
    <div>
      <label>{label->React.string}</label>
      <input
        // input comes from the form.field
        value={form.field->FieldParse.String.Field.input}
        // Changes are made by calling form.actions functions
        onChange={e => {
          let target = e->ReactEvent.Form.target
          target["value"]->form.actions.set
        }}
      />
      // Errors are taken from form.field
      {form.field->FieldParse.String.Field.printError->Option.map(React.string)->Option.or(React.null)}
    </div>
  }
}

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

// Combine the Generic and child Fields to create a product field
module Field = FieldProduct.Product2.Make(
  Generic,
  FieldUsername,
  FieldPassword,
)

// Create a runtime context that includes validations
let contextValidate: Field.context = {
  validate: ({username, password}) => {
    Ok()
    ->Result.guard(_ => username != password, "Username and password must be different")
    ->Promise.return
    // Simulate async
    ->Promise.delay(~ms=1000)
  },
  inner: {
    username: {validate: FieldParse.String.length(~min=2, ())},
    password: {validate: FieldParse.String.length(~min=6, ())},
  }
}

// Create a hook for running this field
module Form = UseField.Make(Field)

module Input = {
  // Render the inputs for a longin
  @react.component
  let make = (~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
    // All composite fields will provide "split" to traverse into their children
    // These children will boe Form.t for each child field respectively
    let {username, password} = form->Field.split

    <div>
      <InputString label="Username" form=username />
      <InputString label="Password" form=password />
    </div>
  }
}

@react.component
let make = (~onSubmit) => {
  let form = Form.use(.
    ~context=contextValidate,
    ~init=None,
  )

  let handleSubmit = React.useMemo1( () => {
    (_) => form.field->Field.output->Option.map(onSubmit)->Option.void
  }, [form.field->Field.output])

  <form onSubmit={handleSubmit}>
    <div className="container">
      <h1>{"Login"->React.string}</h1>
      <Input form />
      <button type_="submit"> {"Sign In"->React.string} </button>
    </div>
  </form>
}
