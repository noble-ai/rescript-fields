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

module InputUsername = {
  @react.component
  let make = (~form: Fields.Form.t<FieldUsername.t, FieldUsername.actions<()>>) => {
    <div>
      <label>{"Username"->React.string}</label>
      <input
        value={form.field->FieldUsername.input}
        onChange={e => {
          let target = e->ReactEvent.Form.target
          target["value"]->form.actions.set
        }}
      />
      {form.field->FieldUsername.printError->Option.map(React.string)->Option.or(React.null)}
    </div>
  }
}

module InputPassword = {
  @react.component
  let make = (~form: Fields.Form.t<FieldPassword.t, FieldPassword.actions<()>>) => {
    <div>
      <label>{"Password"->React.string}</label>
      <input
        // type_="password"
        value={form.field->FieldPassword.input}
        onChange={e => {
          let target = e->ReactEvent.Form.target
          target["value"]->form.actions.set
        }}
        // onBlur={_ => form.actions.validate()}
      />
      {form.field->FieldPassword.printError->Option.map(React.string)->Option.or(React.null)}
    </div>
  }
}

module Input = {
  @react.component
  let make = (~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
    let {username, password} = form->Field.split

    <div>
      <InputUsername form=username />
      <InputPassword form=password />
    </div>
  }
}

@react.component
let make = (~onSubmit) => {
  let form = Form.use(. 
    ~context={
      inner: {
        username: {validate: FieldParse.String.length(~min=2, ())},
        password: {validate: FieldParse.String.length(~min=2, ())},
      },
    },
    ~init=None,
    ~validateInit=false,
  )

  let handleSubmit = React.useMemo1( () => {
    (_) => form.field->Field.output->Option.map(onSubmit)->Option.void
  }, [form.field->Field.output])

  <form onSubmit={handleSubmit}>
    <h1>{"Login"->React.string}</h1> 
    <Input form />
    <button type_="submit"> {"Sign In"->React.string} </button>
  </form>
}
