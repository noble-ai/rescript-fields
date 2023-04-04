open Jest
open FieldProduct

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
