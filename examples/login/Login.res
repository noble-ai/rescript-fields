module FieldPassword = FieldString.Make({
  let validateImmediate = true 
})

module FieldUsername = FieldString.Make({
  let validateImmediate = true 
})


module FieldThird = FieldString.Make({
  let validateImmediate = true 
})

module FieldFourth = FieldString.Make({
  let validateImmediate = true 
})

module Login1Vector = {
  module Field = FieldVector.Vector1.Make(
    {
      let validateImmediate = false
    },
    FieldPassword,
  )

  // Create a hook for running this field
  module Form = UseField.Make(Field)

  @react.component
  let make = (~onSubmit) => {
    let contextPassword: FieldPassword.context = {validate: FieldString.length(~min=2, ())}
    let contextInner: Field.contextInner = (contextPassword, ())
    let context: Field.context = {
        inner: contextInner,
      }

    let form = Form.use(. 
      ~context,
      ~init=None,
      ~validateInit=false,
    )

    let handleSubmit = React.useMemo1( () => {
      (_) => form.field->Field.output->Option.map(onSubmit)->Option.void
    }, [form.field->Field.output])

    let (password, _) = Field.split(form)
    <form onSubmit={handleSubmit}>
      <div>
      <h1>{"Login1Vector"->React.string}</h1>
        <input
          // type_="password"
          value={password.field->FieldPassword.input}
          onChange={e => {
            let target = e->ReactEvent.Form.target
            target["value"]->password.actions.set
          }}
          // onBlur={_ => password.actions.validate()}
        />
        {password.field->FieldPassword.printError->Option.map(React.string)->Option.or(React.null)}
      </div>
      <button type_="submit"> {"Sign In"->React.string} </button>
    </form>
  }
}

module Login1 = {
  // Declare the structure of your desired output type
  // This is outside of Generic to make accessors more easily available
  @deriving(accessors)
  type structure<'a> = {
    password: 'a,
  }

  // Give fields a map from your output type to a generic container (tuple)
  module Generic = {
    type structure<'a> = structure<'a>

    let order = ({password}) => password
    let fromTuple = (password) => {password: password}
  }

  module Field = FieldProduct.Product1.Make(
    {
      let validateImmediate = false
    },
    Generic,
    FieldPassword,
  )

  // Create a hook for running this field
  module Form = UseField.Make(Field)

  @react.component
  let make = (~onSubmit) => {
    let contextPassword: FieldPassword.context = {validate: FieldString.length(~min=2, ())}
    let contextInner: Field.contextInner = {
          password: contextPassword,
        }

    let context: Field.context = {
        inner: contextInner,
      }

    let form = Form.use(. 
      ~context,
      ~init=None,
      ~validateInit=false,
    )

    let handleSubmit = React.useMemo1( () => {
      (_) => form.field->Field.output->Option.map(onSubmit)->Option.void
    }, [form.field->Field.output])

    let {password} = Field.split(form)
    <form onSubmit={handleSubmit}>
      <div>
        <h1>{"Login1"->React.string}</h1>
        <input
          // type_="password"
          value={password.field->FieldPassword.input}
          onChange={e => {
            let target = e->ReactEvent.Form.target
            target["value"]->password.actions.set
          }}
          // onBlur={_ => password.actions.validate()}
        />
        {password.field->FieldPassword.printError->Option.map(React.string)->Option.or(React.null)}
      </div>
      <button type_="submit"> {"Sign In"->React.string} </button>
    </form>
  }
}


// Declare the structure of your desired output type
// This is outside of Generic to make accessors more easily available
@deriving(accessors)
type structure<'a, 'b, 'c, 'd> = {
  username: 'b,
  password: 'a,
  third: 'c,
  fourth: 'd,
}

// Give fields a map from your output type to a generic container (tuple)
module Generic = {
  type structure<'a, 'b, 'c, 'd> = structure<'a, 'b, 'c, 'd>

  let order = (password, username, third, fourth)
  let fromTuple = ((password, username, third, fourth)) => {username, password, third, fourth}
}

module Field = FieldProduct.Product4.Make(
  {
    let validateImmediate = false
  },
  Generic,
  FieldUsername,
  FieldPassword,
  FieldThird,
  FieldFourth,
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
        third: {},
        fourth: {}
      },
    },
    ~init=None,
    ~validateInit=false,
  )

  let handleSubmit = React.useMemo1( () => {
    (_) => form.field->Field.output->Option.map(onSubmit)->Option.void
  }, [form.field->Field.output])

  let {username, password, third, fourth} = Field.split(form)
  <form onSubmit={handleSubmit}>
    <div>
      <h1>{"Login"->React.string}</h1>
      <input
        value={username.field->FieldUsername.input}
        onChange={e => {
          let target = e->ReactEvent.Form.target
          target["value"]->username.actions.set
        }}
      />
      {username.field->FieldUsername.printError->Option.map(React.string)->Option.or(React.null)}
      <input
        // type_="password"
        value={password.field->FieldPassword.input}
        onChange={e => {
          let target = e->ReactEvent.Form.target
          target["value"]->password.actions.set
        }}
        // onBlur={_ => password.actions.validate()}
      />
      {password.field->FieldPassword.printError->Option.map(React.string)->Option.or(React.null)}
      <input
        value={third.field->FieldUsername.input}
        onChange={e => {
          let target = e->ReactEvent.Form.target
          target["value"]->third.actions.set
        }}
      />
      <input
        value={fourth.field->FieldUsername.input}
        onChange={e => {
          let target = e->ReactEvent.Form.target
          target["value"]->fourth.actions.set
        }}
      />

    </div>
    <button type_="submit"> {"Sign In"->React.string} </button>
  </form>
}
