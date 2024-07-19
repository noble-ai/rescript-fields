open Vitest
// shadow global Dynamic with the impl chosen by FT

let itHasLength = (res, len) => {
	itPromise(`emits ${len->Int.toString} states`, () => {
		res->Promise.tap( res => res->Array.length->expect->toEqual(len) )
	})
}


let itHasLengthMin = (res, min) => {
	itPromise(`emits at least ${min->Int.toString} state`, () => {
				res->Promise.tap( res => res->Array.length->expect->toBeGreaterThanOrEqualInt(min) )
	})
}

describe("FieldString", () => {
  module Field = FieldString.Make({ let validateImmediate = true })
	describe("context default", () => {
		let context: Field.context = {}
		describe("makeDyn", () => {
			describe("clear", () => {
				let test = () => { 
					let set = Rxjs.Subject.makeEmpty()
					let val = Rxjs.Subject.makeEmpty()
					let {first, dyn} = Field.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
					let current: ref<'a> = {contents: first}
					let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

					current.contents.pack.actions.clear()
					current.contents.close()
					res
				}

				itHasLength(test(), 2)
				itPromise("first Emits init", () => {
					test()->Promise.tap( res => res->Array.getUnsafe(0)->Close.pack->Form.field->Field.enum->expect->toEqual(#Init))
				})
				itPromise("finally emits valid", () => {
					test()->Promise.tap( res => {
						res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Field.enum->expect->toEqual(#Valid)
					})
				})
			})
		})
	})
	describe("context with validate", () => {
		let context: Field.context = {
			validate: (_x) => Ok()->Promise.return
		}
		describe("clear", () => {
			let test = () => {
				let set = Rxjs.Subject.makeEmpty()
				let val = Rxjs.Subject.makeEmpty()
				let {first, dyn} = Field.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
					let current: ref<'a> = {contents: first}
				let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory


				current.contents.pack.actions.validate()
				current.contents.pack.actions.clear()
				Promise.sleep(50)->Promise.tap(_ => current.contents.close())->Promise.void
				res
			}

			itPromise("emits init first", () => {
				test()->Promise.tap( res => res->Array.getUnsafe(0)->Close.pack->Form.field->Field.enum->expect->toEqual(#Init))
			})

			itPromise("emits busy", () => {
				test()->Promise.tap( res => res->Array.map(x => x->Close.pack->Form.field->Field.enum)->expect->toContainArray(#Busy))
			})

			itPromise("ends valid", () => {
				test()->Promise.tap( res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Field.enum->expect->toEqual(#Valid))
			})

		})
		describe("set", () => {
			let value = "test"
			let test = () => {
				let set = Rxjs.Subject.makeEmpty()
				let val = Rxjs.Subject.makeEmpty()

				let {first, dyn} = Field.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
					let current: ref<'a> = {contents: first}
				let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

				current.contents.pack.actions.validate()
				current.contents.pack.actions.set(value)
				Promise.sleep(50)->Promise.tap(_ => current.contents.close())->Promise.void
				res
			}
			itPromise("emits init first", () => {
				test()->Promise.tap( res => res->Array.getUnsafe(0)->Close.pack->Form.field->Field.enum->expect->toEqual(#Init))
			})
			itPromise("emits busy", () => {
				test()->Promise.tap( res => res->Array.map(x => x->Close.pack->Form.field->Field.enum)->expect->toContainArray(#Busy))
			})
			itPromise("ends valid", () => {
				test()->Promise.tap( res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Field.enum->expect->toEqual(#Valid))
			})
			itPromise("captures input with a busy state", () => {
				test()
				->Promise.tap( res => {
					res
					->Array.map(x => x->Close.pack->Form.field)
					->Array.filter(x => x->Field.enum == #Busy)
					->Array.map(Field.input)
					->expect
					->toContainArray(value)
				})
			})
			itPromise("keeps input when valid", () => { 
				test()->Promise.tap( res => res->Array.getUnsafe(2)->Close.pack->Form.field->Field.input->expect->toEqual(value))
			})
		})
	})	
	describe("context with async validate", () => {
		let slow = "slow"
		let fast = "fast"
		let context: Field.context = {
			validate: (x) => {
				if x == slow {
					Promise.sleep(100)->Promise.const(Ok())
				} else {
					Ok()->Promise.return
				}
			}
		}

		describe("set after set", () => { 
			let test = () => {
				let set = Rxjs.Subject.makeEmpty()
				let val = Rxjs.Subject.makeEmpty()
				let {first, dyn} = Field.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
					let current: ref<'a> = {contents: first}
				let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

				current.contents.pack.actions.validate()
				current.contents.pack.actions.set(slow)
				current.contents.pack.actions.set(fast)
				Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void

				res
			}

			itPromise("ends valid", () => {
				test()->Promise.tap( res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Field.enum->expect->toEqual(#Valid))
			})
			itPromise("keeps second input when valid", () => { 
				test()->Promise.tap( res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Field.output->expect->toEqual(Some("fast")))
			})
		})
	})
})
