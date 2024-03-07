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

  <form onSubmit={field.handleSubmit(onSubmit)}>
    {
      let {username, password} = field.field->Field.inner
      <div>
			<input
				value={username->FieldUsername.input}
				onChange={e => {
					let target = e->ReactEvent.Form.target
					target["value"]->FieldUsername.makeSet->Field.actions.username->field.reduce
				}}
			/>
			{ password
				->FieldUsername.printError
				->Option.map(React.string)
				->Option.or(React.null)
			}
			<input
				type_="password"
				value={password->FieldPassword.input}
				onChange={e => {
					let target = e->ReactEvent.Form.target
					target["value"]->FieldPassword.makeSet->Field.actions.password->field.reduce
				}}
				onBlur={(_) => #Validate->Field.actions.password->field.reduce}
			 />
				{ password
					->FieldPassword.printError
					->Option.map(React.string)
					->Option.or(React.null)
				}
      </div>
    }
		<button
			type_="submit"
			>{"Sign In"->React.string}
		</button>
  </form>
}