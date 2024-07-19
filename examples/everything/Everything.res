module FieldLogin = Login.Field

module InputString = {
	@react.component
	let make = (~value, ~set) => {
		<input
			value
			onChange={e => {
				e->ReactEvent.Form.preventDefault
				e->ReactEvent.Form.stopPropagation
				let target = e->ReactEvent.Form.target
				target["value"]->set
			}}
		/>
	}
}

module InputOptString = {
	@react.component
	let make = (~value, ~clear, ~set) => {
		<input
			value={value->Option.or("")}
			onChange={e => {
				let target = e->ReactEvent.Form.target
				switch target["value"] {
					| "" => clear()
					| x => set(x)
				}
			}}
		/>
	}
}



module Status = {
	@react.component
	let make = (~enum: Store.enum, ~error) => {
		<div className="status">{error->Option.or(enum->Store.enumToPretty)->React.string}</div>
	}
}

module State = {
	type t = [#Alabama | #Alaska | #Arizona | #Arkansas | #California | #Colorado | #Connecticut | #Delaware | #Florida | #Georgia | #Hawaii | #Idaho | #Illinois | #Indiana | #Iowa | #Kansas | #Kentucky | #Louisiana | #Maine | #Maryland | #Massachusetts | #Michigan | #Minnesota | #Mississippi | #Missouri | #Montana | #Nebraska | #Nevada | #NewHampshire | #NewJersey | #NewMexico | #NewYork | #NorthCarolina | #NorthDakota | #Ohio | #Oklahoma | #Oregon | #Pennsylvania | #RhodeIsland | #SouthCarolina | #SouthDakota | #Tennessee | #Texas | #Utah | #Vermont | #Virginia | #Washington | #WestVirginia | #Wisconsin | #Wyoming]
	let all: array<t> = [#Alabama, #Alaska, #Arizona, #Arkansas, #California, #Colorado, #Connecticut, #Delaware, #Florida, #Georgia, #Hawaii, #Idaho, #Illinois, #Indiana, #Iowa, #Kansas, #Kentucky, #Louisiana, #Maine, #Maryland, #Massachusetts, #Michigan, #Minnesota, #Mississippi, #Missouri, #Montana, #Nebraska, #Nevada, #NewHampshire, #NewJersey, #NewMexico, #NewYork, #NorthCarolina, #NorthDakota, #Ohio, #Oklahoma, #Oregon, #Pennsylvania, #RhodeIsland, #SouthCarolina, #SouthDakota, #Tennessee, #Texas, #Utah, #Vermont, #Virginia, #Washington, #WestVirginia, #Wisconsin, #Wyoming]
		
	external show: t => string = "%identity"
	external fromStringUnsafe: string => t = "%identity"

	module Field = FieldIdentity.Make({
		type t = t
		let empty = #Ohio
		let show = show
	})

	module Input = {
		@react.component
		let make = (~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
			<div>
				<select
					value={form.field->Field.input->show}
					onChange={e => {
						let target = e->ReactEvent.Form.target
						target["value"]->form.actions.set
					}}
				>
					{all->Array.map(state => {
						<option key={state->show} value={state->show}>{state->show->React.string}</option>
					})->React.array}
				</select>
				<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
			</div>
		}
	}
}

module String = {
	module Field = FieldParse.String.Field

	module Input = {
		@react.component
		let make = (~label, ~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
			<>
				<div>
					<label>{label->React.string}</label>
					<input
						value={form.field->Field.input}
						onChange={e => {
							let target = e->ReactEvent.Form.target
							target["value"]->form.actions.set
						}}
					/>
					<Status enum={form.field->Field.enum} error={form.field->Field.printError} />
				</div>
			</>
		}
	}
}

module Zip = {
	module Field = FieldOpt.Make(FieldParse.Int)

	let contextDefault: Field.context = {
		validate: (zip) => {
			if zip < 501 {
				Error("The lowest zip code is 00501 (Internal Revenue Service)")
			} else if zip > 99950 {
				Error("The biggest zip code is 99950 (Ketchikan, Ak)")
			} else {
				Ok()
			}
			->Promise.return
			->Promise.delay(~ms=1000)
		}
	}

	module Input = {
		@react.component
		let make = (~form: Form.t<Field.t, Field.actions<()>>) => {
			<div>
				<label>{"Zip"->React.string}</label>
				<input
					value={form.field->Field.input->Option.or("")}
					onChange={e => {
						let target = e->ReactEvent.Form.target
						switch target["value"] {
							| "" => form.actions.clear()
							| x => form.actions.inner.set(x)
						}
					}}
				/>
				<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
			</div>
		}
	}
}

module OptState = {
	module Field = FieldOpt.Make(State.Field)

	module Input = {
		@react.component
		let make = (~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
			<div>
				<label>{"State"->React.string}</label>
				<select
					value={form.field->Field.input->Option.map(State.show)->Option.or("")}
					onChange={e => {
						let target = e->ReactEvent.Form.target
						switch target["value"] {
							| "" => form.actions.clear()
							| x => x->State.fromStringUnsafe->form.actions.inner.set
						}
					}}
				>
					<option value="">{"Select a state"->React.string}</option>
					{ State.all
						->Array.map(state => <option value={state->State.show}>{state->State.show->React.string}</option>)
						->React.array
					}
				</select>
				<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
			</div>
		}
	}
}

module AddressStreet = {
	@deriving(accessors)
	type structure<'street, 'city, 'state, 'zip> = {
		street: 'street,
		city: 'city,
		state: 'state,
		zip: 'zip,
	}

	module FieldStreet = String.Field
	module FieldCity = String.Field
	module FieldState = OptState.Field
	module FieldZip = Zip.Field

	module Gen = {
		type structure<'a, 'b, 'c, 'd> = structure<'a, 'b, 'c, 'd>
		let order = (street, city, state, zip)
		let fromTuple = ((street, city, state, zip)) => {street, city, state, zip}
	}

	module Field = FieldProduct.Product4.Make(Gen, FieldStreet, FieldCity, FieldState, FieldZip)

	let contextDefault: Field.context = {
		inner: {
			street: {},
			city: {},
			state: {},
			zip: {}
		}
	}

	module Input = {
		@react.component
		let make = (~form: Form.t<Field.t, Field.actions<()>>) => {
			let {street, city, state, zip} = form->Field.split
			<div>
				<String.Input label="Street" form=street />
				<div className="row">
					<div className="column">
						<String.Input label="City" form=city />
					</div>
					<div className="column">
						<OptState.Input form=state />
					</div>
					<div className="column">
						<Zip.Input form=zip />
					</div>
				</div>
			</div>
		}
	}
}

module AddressMilitary = {
	module Segment = {
		type t = [#Unit | #Community | #Postal ]
		let all: array<t> = [#Unit, #Community, #Postal ]
			
		external show: t => string = "%identity"
		external fromStringUnsafe: string => t = "%identity"

		module Field = FieldOpt.Make(FieldIdentity.Make({
			type t = t
			let empty = #Unit 
			let show = show
		}))

		module Input = {
			@react.component
			let make = (~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
				<div>
				  <label className="label">{"Segment"->React.string}</label>
					<select
						value={form.field->Field.input->Option.map(show)->Option.or("")}
						onChange={e => {
							let target = e->ReactEvent.Form.target
							switch target["value"] {
								| "" => form.actions.clear()
								| x => x->fromStringUnsafe->form.actions.inner.set
							}
						}}
					>
						{all->Array.map(value => {
							<option key={value->show} value={value->show}>{value->show->React.string}</option>
						})->React.array}
					</select>
					<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
				</div>
			}
		}
	}

	module Branch = {
		type t = [#Apo | #Fpo ]
		let all: array<t> = [#Apo, #Fpo ]
			
		external show: t => string = "%identity"
		external fromStringUnsafe: string => t = "%identity"

		module Field = FieldOpt.Make(FieldIdentity.Make({
			type t = t
			let empty = #Apo
			let show = show
		}))

		module Input = {
			@react.component
			let make = (~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
				<div>
				  <label className="label">{"Branch"->React.string}</label>
					<select
						value={form.field->Field.input->Option.map(show)->Option.or("")}
						onChange={e => {
							let target = e->ReactEvent.Form.target
							switch target["value"] {
								| "" => form.actions.clear()
								| x => x->fromStringUnsafe->form.actions.inner.set
							}
						}}
					>
						{all->Array.map(value => {
							<option key={value->show} value={value->show}>{value->show->React.string}</option>
						})->React.array}
					</select>
					<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
				</div>
			}
		}
	}

	module Theater = {
		type t = [#Americas | #Pacific | #Europe ]
		let all: array<t> = [#Americas, #Pacific, #Europe ]
			
		external show: t => string = "%identity"
		external fromStringUnsafe: string => t = "%identity"

		module Field = FieldOpt.Make(FieldIdentity.Make({
			type t = t
			let empty = #Americas
			let show = show
		}))

		module Input = {
			@react.component
			let make = (~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
				<div>
				  <label className="label">{"Theater"->React.string}</label>
					<select
						value={form.field->Field.input->Option.map(show)->Option.or("")}
						onChange={e => {
							let target = e->ReactEvent.Form.target
							switch target["value"] {
							| "" => form.actions.clear()
							| x => x->fromStringUnsafe->form.actions.inner.set
							}
						}}
					>
						{all->Array.map(value => {
							<option key={value->show} value={value->show}>{value->show->React.string}</option>
						})->React.array}
					</select>
					<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
				</div>
			}
		}
	}

	module Int = {
		module Field = FieldParse.Int
		module Input = {
			@react.component
			let make = (~label, ~form: Fields.Form.t<Field.t, Field.actions<()>>) => {
				<>
					<div>
						<label className="label">{label->React.string}</label>
						<InputString value={form.field->Field.input} set=form.actions.set />
						<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
					</div>
				</>

			}
		}
	}

	@deriving(accessors)
	type structure<'segment, 'numsegment, 'box, 'branch, 'theater, 'zip> = {
		segment: 'segment,
		numSegment: 'numsegment,
		box: 'box,
		branch: 'branch,
		theater: 'theater,
		zip: 'zip
	}

	module Gen = {
		type structure<'a, 'b, 'c, 'd, 'e, 'f> = structure<'a, 'b, 'c, 'd, 'e, 'f>
		let order = (segment, numSegment, box, branch, theater, zip)
		let fromTuple = ((segment, numSegment, box, branch, theater, zip)) => {segment, numSegment, box, branch, theater, zip} 
	}

	module Field = FieldProduct.Product6.Make(
		Gen,
		Segment.Field, Int.Field, Int.Field, Branch.Field, Theater.Field, Zip.Field
	)
		
	let contextDefault: Field.context = {
		inner: {
			segment: {},
			numSegment: {},
			box: {},
			branch: {},
			theater: {},
			zip: {}
		}
	}

	module Input = {
		@react.component
		let make = (~form: Form.t<Field.t, Field.actions<()>>) => {
			let {segment, numSegment, box, branch, theater, zip} = form->Field.split
			<div>
			  <div className="row">
					<div className="column column-20"><Segment.Input form=segment /></div>
					<div className="column float-left"><Int.Input label="\u00A0" form=numSegment /></div>
					<div className="column float-left"><Int.Input label="box" form=box /></div>
				</div>
			  <div className="row">
					<div className="column"><Branch.Input form=branch /></div>
					<div className="column"><Theater.Input form=theater /></div>
					<div className="column"><Zip.Input form=zip /></div>
				</div>
			</div>
		}
	}
}

module Address = {
	type sum<'a, 'b> = Street('a) | Military('b)

	module Sum = {
		type t<'a, 'b> = sum<'a, 'b>
		let toSum = x => switch x {
			| Street(x) => #B(x)
			| Military(x) => #A(x)
		}
		let fromSum = x => switch x {
			| #B(x) => Street(x)
			| #A(x) => Military(x)
		}
	}

	module Gen = {
		@deriving(accessors)
		type structure<'a, 'b> = {
			street: 'a,
			military: 'b
		}
		let order = (street, military)
		let fromTuple = ((street, military)) => {street, military}
	}

	module FieldStreet = AddressStreet.Field
	module FieldMilitary = AddressMilitary.Field

	module Field = FieldSum.Sum2.Make(Sum, Gen, FieldStreet, FieldMilitary)

	let contextDefault: Field.context = {
		inner: {
			street: AddressStreet.contextDefault,
			military: AddressMilitary.contextDefault
		}
	}

	module Input = {
		@react.component
		let make = (~form: Form.t<Field.t, Field.actions<()>>) => {
			let setStreet = e => {
				e->ReactEvent.Mouse.preventDefault
				e->ReactEvent.Mouse.stopPropagation
				form.actions.set(Street({street: "", city: "", state: None, zip: None}))
			}
			let setMilitary = e => {
				e->ReactEvent.Mouse.preventDefault
				e->ReactEvent.Mouse.stopPropagation
				form.actions.set(Military({segment: None, numSegment: "", box: "", branch: None, theater: None, zip: None}))
			}
			<div>
				<button className="button-clear" onClick={setStreet}>{"Street"->React.string}</button>
				<button className="button-clear" onClick={setMilitary}>{"Military"->React.string}</button>
				{ switch form->Field.split {
					| Street(form) => <AddressStreet.Input form />
					| Military(form) => <AddressMilitary.Input form />
					}
				}
				<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
			</div>
		}
	}
}

module Addresses = {
	module Field = FieldArray.Make(
		Address.Field,
		{
		type t = Address.Field.t
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
			<div>
			{ forms->Array.mapi((f, i) => {
				// let key: string = f.field->State.FieldOpt.input->Option.map(State.show)->Option.or("null")
				// let key = `${i->Int.toString}`
				<div className="row">
					<div className="column">
						<Address.Input form=f/>
					</div>
					<button className="button-clear" onClick={handleRemove(~index=i)}>{"✕"->React.string}</button>
				</div>
			})->React.array }
			<div className="row">
				<Status enum={form.field->Field.enum} error={form.field->Field.printError}/>
			</div>
			<button  className="button-clear" onClick={handleAdd}>{"Add One"->React.string}</button>
			</div>
		}
	}
}

// Create a hook for running this field
module Field = Addresses.Field
module Form = UseField.Make(Field)

let init: Field.input = [
	Street({
		street: "123 Hhaa",
		city: "Fort Collines",
		state: Some(#Alabama),
		zip: Some("444"),
	}),
	Military({
		segment: Some(#Community),
		numSegment: "300",
		box: "abc",
		branch: Some(#Apo),
		theater: Some(#Europe),
		zip: Some("")
	})
]

@react.component
let make = (~onSubmit) => {
  let form = Form.use(. 
    ~context=Addresses.contextDefault,
    ~init=Some(init),
    ~validateInit=false,
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