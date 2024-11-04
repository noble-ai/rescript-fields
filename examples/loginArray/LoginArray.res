module Status = {
  @react.component
  let make = (~title=?, ~enum: Store.enum, ~error) => {
    <div className={`status ${enum->Store.enumToA}`}>
      {title->Option.map(x => `${x}: `->React.string)->Option.or(React.null)}
      {`${error->Option.or(enum->Store.enumToPretty)}`->React.string}
    </div>
  }
}

module LoginArray = {
  module Field = FieldArray.Make(
    Login.Field,
    {
      type t = Login.Field.t
      let filter = FieldArray.filterIdentity
    },
  )

  let validate = (out: Field.output) => {
    if out->Array.length < 2 {
      Error("Must choose at least two logins")
    } else {
      Ok()
    }
    ->Promise.return
    ->Promise.delay(~ms=1000)
  }

  let contextDefault: Field.context = {
    validate,
    empty: _ => [],
    element: Login.contextValidate,
  }

  module Input = {
    @react.component
    let make = (~form: Fields.Form.t<Field.t, Field.actions<unit>>) => {
      let forms = form->Field.split

      let handleAdd = e => {
        e->ReactEvent.Mouse.preventDefault
        e->ReactEvent.Mouse.stopPropagation
        form.actions.add(None)
      }
      let handleRemove = (~index, e) => {
        e->ReactEvent.Mouse.preventDefault
        e->ReactEvent.Mouse.stopPropagation
        form.actions.remove(index)
      }
      let handleClear = e => {
        e->ReactEvent.Mouse.preventDefault
        e->ReactEvent.Mouse.stopPropagation
        form.actions.clear()
      }

      let handleReset = e => {
        e->ReactEvent.Mouse.preventDefault
        e->ReactEvent.Mouse.stopPropagation
        form.actions.reset()
      }

      <div>
        {forms
        ->Array.mapi((f, i) => {
          <div className="row" key=`${i->Int.toString}`>
            <div className="column">
              <Login.Input form=f />
            </div>
            <button className="button-clear" onClick={handleRemove(~index=i)}>
              {"✕"->React.string}
            </button>
          </div>
        })
        ->React.array}
        <div className="row">
          <Status
            title="Addresses" enum={form.field->Field.enum} error={form.field->Field.printError}
          />
        </div>
        <div className="row">
          <button className="button-clear column column-20" onClick={handleAdd}>
            {"Add One"->React.string}
          </button>
          <button className="button-clear float-left" onClick={handleReset}>
            {"Reset"->React.string}
          </button>
          <button className="button-clear float-left" onClick={handleClear}>
            {"Clear"->React.string}
          </button>
        </div>
      </div>
    }
  }
}

module Field = LoginArray.Field
module Form = UseField.Make(Field)

@react.component
let make = (~onSubmit) => {
  let form = Form.use(.
    ~context=LoginArray.contextDefault,
    ~init=None,
    ~validateInit=false,
  )

  Js.log2("form.field: ", form.field->Field.show)

  let handleSubmit = React.useMemo1( () => {
    (_) => form.field->Field.output->Option.map(onSubmit)->Option.void
  }, [form.field->Field.output])

	<div className="container">
		<form onSubmit={handleSubmit}>
			<h2>{"Addresses"->React.string}</h2>
			<LoginArray.Input form />
			<button type_="submit"> {"Sign In"->React.string} </button>
		</form>
	</div>
}