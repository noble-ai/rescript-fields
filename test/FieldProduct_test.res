open Vitest
// prefer shadowing Dynamic
open! FieldTrip
open FieldProduct

module Gen2 = {
	@deriving(accessors)
	type structure<'a, 'b> = {
		left: 'a,
		right: 'b
	}
	let order = (left, right)
	let fromTuple = ((left, right)) => { left, right }
}

module FieldString = FieldString.Make({
  let validateImmediate = false
})


describe("FieldProduct", () => {
	describe("Product2", () => {
	module Subject = Product2.Make({
			let validateImmediate = false
		}, Gen2, FieldString, FieldString);

		let context: Subject.context = {
			inner: {
				left: { },
				right: { }
			}
		}

		let left: FieldString.t = Valid("a", "a")
		let right: FieldString.t = Valid("b", "b")
		let store: Subject.t = Dirty({ left: left, right: right })
		describe("#Validate", () => {
			let res = Subject.validate(false, context, store)
			itPromise("resolves to a valid Subject.t", () => {
				res->Dynamic.toPromise->Promise.map( v => expect(v)->toEqual(Valid({ left: left, right: right }, {left: "a", right: "b" })) )
			})
		})
	})
})
