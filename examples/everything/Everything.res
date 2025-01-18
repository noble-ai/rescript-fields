module Addresses = {
	module FieldElement = Address.Field
	module Field = FieldArray.Make(
		FieldElement,
		{
		type t = FieldElement.t
		let filter = FieldArray.filterIdentity
	})

	let validate = (out: Field.output) => {
		if (out->Array.length < 2) {
			Error("Must choose at least two adddresses")
		} else {
			Ok()
		}->Promise.return
		->Promise.delay(~ms=1000)
	}

	let contextDefault: Field.context = {
		validate: validate,
		empty: _ => [],
		element: Address.contextDefault
	}

	module Input = {
		@react.component
		let make = (~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
			let forms = form->Field.split

			let handleAdd = (e) => {
				e->ReactEvent.Mouse.preventDefault
				e->ReactEvent.Mouse.stopPropagation
				form.actions.add(None)
			}
			let handleRemove = (~index, e) => {
				e->ReactEvent.Mouse.preventDefault
				e->ReactEvent.Mouse.stopPropagation
				form.actions.remove(index)
			}
			let handleClear = (e) => {
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
				{ forms->Array.mapi(((key, f), i) => {
					<div className="row" key={key->Belt.Int.toString}>
						<div className="column">
							<Address.Input form=f/>
						</div>
						<button className="button-clear" onClick={handleRemove(~index=i)}>{"✕"->React.string}</button>
					</div>
				})->React.array }
				<div className="row">
					<StatusExample title="Addresses" enum={form.field->Field.enum} error={form.field->Field.printError}/>
				</div>
				<div className="row">
					<button  className="button-clear column column-20" onClick={handleAdd}>{"Add One"->React.string}</button>
					<button  className="button-clear float-left" onClick={handleReset}>{"Reset"->React.string}</button>
					<button  className="button-clear float-left" onClick={handleClear}>{"Clear"->React.string}</button>
				</div>
			</div>
		}
	}
}

// Create a hook for running this field
module Field = Addresses.Field
module Form = UseField.Make(Field)

let init: Field.input = [
	Street({
		street: Some("123 Hhaa"),
		city: Some("Fort Collines"),
		state: Some(#Alabama),
		zip: Some("44400"),
	}),
	Military({
		segment: Some(#Community),
		numSegment: Some("300"),
		box: Some("123"),
		branch: Some(#Apo),
		theater: Some(#Europe),
		zip: Some("99900")
	})
]

@react.component
let make = (~onSubmit) => {
  let form = Form.use(.
    ~context=Addresses.contextDefault,
    ~init=Some(Validate(init)),
  )

  let handleSubmit = React.useMemo1( () => {
    (_) => form.field->Field.output->Option.map(onSubmit)->Option.void
  }, [form.field->Field.output])

	<div className="container">
		<form onSubmit={handleSubmit}>
			<h2>{"Addresses"->React.string}</h2>
			<Addresses.Input form />
			<button type_="submit"> {"Sign In"->React.string} </button>
		</form>
	</div>
}