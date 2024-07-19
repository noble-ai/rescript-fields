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
  let form = Form.use(. 
    ~context={
      inner: {
        username: {validate: FieldString.length(~min=2, ())},
        password: {validate: FieldString.length(~min=2, ())},
      },
    },
    ~init=Some({username: "", password: ""}),
    ~validateInit=false,
  )

  let handleSubmit = React.useMemo1( () => {
    (_) => form.field->Field.output->Option.map(onSubmit)->Option.void
  }, [form.field->Field.output])

  let {username, password} = Field.split(form)
  <form onSubmit={handleSubmit}>
    {<div>
      {
        let {field, actions} = username
        <>
          <input
            value={field->FieldUsername.input}
            onChange={e => {
              let target = e->ReactEvent.Form.target
              target["value"]->actions.set
            }}
          />
          {field->FieldUsername.printError->Option.map(React.string)->Option.or(React.null)}
        </>
      }
      {
        let {field, actions} = password
        <>
          <input
            type_="password"
            value={field->FieldPassword.input}
            onChange={e => {
              let target = e->ReactEvent.Form.target
              target["value"]->actions.set
            }}
            onBlur={_ => actions.validate()}
          />
          {field->FieldPassword.printError->Option.map(React.string)->Option.or(React.null)}
        </>
      }
    </div>}
    <button type_="submit"> {"Sign In"->React.string} </button>
  </form>
}
