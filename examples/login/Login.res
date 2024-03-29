module FieldUsername = FieldString.Make({
  let validateImmediate = false
})

module FieldPassword = FieldString.Make({
  let validateImmediate = false
})

// Declare the structure of your desired output type
// This is outside of Generic to make accessors more easily available
@deriving(accessors)
type structure<'a, 'b> = {
  username: 'a,
  password: 'b,
}

// Give fields a map from your output type to a generic container (tuple)
module Generic = {
  type structure<'a, 'b> = structure<'a, 'b>

  let order = (username, password)
  let fromTuple = ((username, password)) => {username, password}
}

module Field = FieldProduct.Product2.Make(
  {
    let validateImmediate = false
  },
  Generic,
  FieldUsername,
  FieldPassword,
)

// Create a hook for running this field
module Form = UseField.Make(Field)

@react.component
let make = (~onSubmit) => {
  let field = Form.use(
    ~context={
      inner: {
        username: {validate: FieldString.length(~min=2, ())},
        password: {validate: FieldString.length(~min=2, ())},
      },
    },
    ~init={username: "", password: ""},
    (),
  )
  let {username, password} = Field.split(field.part)
  <form onSubmit={field.handleSubmit(onSubmit)}>
    {<div>
      {
        let {field, actions_} = username
        <>
          <input
            value={field->FieldUsername.input}
            onChange={e => {
              let target = e->ReactEvent.Form.target
              target["value"]->actions_.set
            }}
          />
          {field->FieldUsername.printError->Option.map(React.string)->Option.or(React.null)}
        </>
      }
      {
        let {field, actions_} = password
        <>
          <input
            type_="password"
            value={field->FieldPassword.input}
            onChange={e => {
              let target = e->ReactEvent.Form.target
              target["value"]->actions_.set
            }}
            onBlur={_ => actions_.validate()}
          />
          {field->FieldPassword.printError->Option.map(React.string)->Option.or(React.null)}
        </>
      }
    </div>}
    <button type_="submit"> {"Sign In"->React.string} </button>
  </form>
}
