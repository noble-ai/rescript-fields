open Jest

module Gen2 = {
	open FieldProduct.Tuple
	type structure<'a, 'b> = {
		left: 'a,
		right: 'b
	}
	let toTuple = ({left, right}: structure<'a, 'b>) => tuple2(left, right)
	let fromTuple = (tuple: tuple2<'a, 'b>) => { left: tuple->get1, right:tuple->get2 }
}
module FieldString = FieldString.Make({
  let validateImmediate = false
})

describe("UseField", () => {
	// describe("applyLatest", () => {

	// })
	describe("applyChange", () => {
		module Subject = FieldProduct.Product2.Make({let validateImmediate = false}, Gen2, FieldString, FieldString)

		let context: Subject.context = {
			inner: {
				left: { },
				right: { }
			}
		}

		describe("Single change", () => {
			let left: FieldString.t = Valid("a", "a")
			let right: FieldString.t = Valid("b", "b")

			// let context: Rxjs.BehaviorSubject.t<Subject.context> = Rxjs.BehaviorSubject.make(context)
			let field: Subject.t = Dirty({left: left, right: right})
			let subject: Rxjs.BehaviorSubject.t<Subject.t> = Rxjs.BehaviorSubject.make(field)
			let changeOut: Rxjs.Subject.t<(int, 'change)> = Rxjs.Subject.makeEmpty()
			let change = Subject.actions.left(#Set("q"))

			let res = UseField.applyChange(
				~reduce=Subject.reduce(~context),
				~subject,
				~setfield=Void.void,
				~changeOut,
				1,
				(change, Void.void, Void.void)
			)

			itPromise("applies change to field", () => {
				res
				->Rxjs.lastValueFrom
				->Promise.map( v => {
					let {left} = v->Subject.input
					expect(left)->toEqual("q")
			 } )
			})
		})
	})
})
