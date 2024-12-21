open Vitest

module Gen2 = {
	@deriving(accessors)
	type structure<'a, 'b> = {
		left: 'a,
		right: 'b
	}
	let order = (left, right)
	let fromTuple = ((left, right)) => { left, right }
}

describe("FieldProduct", () => {
	describe("Product2", () => {
		describe("validate immediate", () => {
			module Subject = FieldProduct.Product2.Make(Gen2, FieldParse.String.Field, FieldParse.String.Field)
			module MkDyn = Test.MkDyn(Subject)

			describe("context default", () => {
				let context: Subject.context = {
					inner: {
						left: { },
						right: { }
					}
				}

				describe("#Validate", () => {
					let left: FieldParse.String.Field.t = Valid("a", "a")
					let right: FieldParse.String.Field.t = Valid("b", "b")
					let store: Subject.t = Dirty({ left: left, right: right })
					let res = Subject.validate(false, context, store)
					itPromise("resolves to a valid Subject.t", () => {
						res->Dynamic.toPromise->Promise.map( v => expect(v)->toEqual(Valid({ left: left, right: right }, {left: "a", right: "b" })) )
					})
				})

				describe("#makeDyn", () => {
					describe("setOuter", () => {
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							]
						)

						itPromise("applies value", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual({left: "haha", right: "nono"}))
						})
					})
				describe("setElement", () => {
					let l = "HEHE"
					let r = "NONO"
					let test = MkDyn.test(context,
						[ #Set({left: "haha", right: "nono"})
						, #Action( ({inner}) => inner.left.set(l) )
						, #Action( ({inner}) => inner.right.set(r) )
						]
					)

					itPromise("Applies inner set left", () => {
						test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual(l))
					})
					itPromise("Applies inner set right", () => {
						test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual(r))
					})
				})
			})
			})

			describe("context validate", () => {
				// Delay each validation progressively less so they all overlap
				let delay: ref<int> = {contents: 100}
				let context: Subject.context = {
					validate: (_x: Subject.output) => {
						let d = delay.contents
						delay.contents = delay.contents - 10
						Promise.sleep(d)->Promise.map(_ => Ok())
					},
					inner: {
						left: { },
						right: { }
					}
				}

				describe("#makeDyn", () => {
					describe("setOuter", () => {
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							, #Set({left: "nono", right: "haha"})
							]
						)

						itPromise("applies last", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
					})
					describe("setElement", () => {
						let l = "HEHE"
						let r = "NONO"
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							, #Action( ({inner}) => inner.right.set(r) )
							, #Action( ({inner}) => inner.left.set(l) )
							]
						)

						itPromise("Applies inner set left", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual(l))
						})
						itPromise("Applies inner set right", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual(r))
						})
					})
				})
			})

			describe("context validate nested", () => {
				// Delay each validation progressively less so they all overlap
				// cant have mroe than 10 validations w this setting
				// but default timeout is 5s so watch out increasing it
				let delay: ref<int> = {contents: 100}
				let validate = (_x: Subject.output) => {
						let d = delay.contents
						delay.contents = delay.contents - 10
						Promise.sleep(d)->Promise.map(_ => Ok())
					}

				let validateString = (_x: FieldParse.String.Field.output) => {
						let d = delay.contents
						delay.contents = delay.contents - 10
						Promise.sleep(d)->Promise.map(_ => Ok())
					}

				let context: Subject.context = {
					validate: validate,
					inner: {
						left: { validate: validateString },
						right: { validate: validateString }
					}
				}

				describe("#makeDyn", () => {
					describe("setOuter", () => {
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							, #Set({left: "nono", right: "haha"})
							]
						)

						let field = res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field
						itPromise("applies last", () => {
							test()->Promise.tap(res => res->field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
						itPromise("resolves to valid", () => {
							test()->Promise.tap(res => res->field->Subject.enum->expect->toEqual(#Valid))
						})
					})
					describe("setElement", () => {
						let l = "HEHE"
						let r = "NONO"

						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							, #Action( ({inner}) => inner.right.set(r) )
							, #Action( ({inner}) => inner.left.set(l) )
							]
						)

						itPromise("Applies inner set left", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual(l))
						})
						itPromise("Applies inner set right", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual(r))
						})
					})
			})
		})
		})

		describe("validate deferred", () => {
			module Subject = FieldProduct.Product2.Make(Gen2, FieldParse.String.Field, FieldParse.String.Field);
			module MkDyn = Test.MkDyn(Subject)

			describe("context default", () => {
				let context: Subject.context = {
					inner: {
						left: { },
						right: { }
					}
				}

				describe("#makeDyn", () => {
					describe("setOuter", () => {
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							]
						)

						itPromise("applies value", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual({left: "haha", right: "nono"}))
						})
					})
					describe("setElement", () => {
						let l = "HEHE"
						let r = "NONO"
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							, #Action( ({inner}) => inner.left.set(l) )
							, #Action( ({inner}) => inner.right.set(r) )
							]
						)

						itPromise("Applies inner set left", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual(l))
						})
						itPromise("Applies inner set right", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual(r))
						})
					})
				})
			})

			describe("context validate", () => {
				// Delay each validation progressively less so they all overlap
				let delay: ref<int> = {contents: 100}
				let context: Subject.context = {
					validate: (_x: Subject.output) => {
						let d = delay.contents
						delay.contents = delay.contents - 10
						Promise.sleep(d)->Promise.map(_ => Ok())
					},
					inner: {
						left: { },
						right: { }
					}
				}

				describe("#makeDyn", () => {
					describe("setOuter", () => {
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							, #Set({left: "nono", right: "haha"})
							]
						)

						itPromise("applies last", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
					})
					describe("setElement", () => {
						let l = "HEHE"
						let r = "NONO"
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							, #Action( ({inner}) => inner.right.set(r) )
							, #Action( ({inner}) => inner.left.set(l) )
							]
						)

						itPromise("Applies inner set left", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual(l))
						})
						itPromise("Applies inner set right", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual(r))
						})
					})
				})
			})

			describe("context validate nested", () => {
				// Delay each validation progressively less so they all overlap
				let delay: ref<int> = {contents: 100}
				let validate = (_x: Subject.output) => {
						let d = delay.contents
						delay.contents = delay.contents - 10
						Promise.sleep(d)->Promise.map(_ => Ok())
					}

				let validateString = (_x: FieldParse.String.Field.output) => {
						let d = delay.contents
						delay.contents = delay.contents - 10
						Promise.sleep(d)->Promise.map(_ => Ok())
					}

				let context: Subject.context = {
					validate: validate,
					inner: {
						left: { validate: validateString },
						right: { validate: validateString }
					}
				}

				describe("#makeDyn", () => {
					describe("setOuter", () => {
						let test = MkDyn.test(context,
							[ #Set({left: "haha", right: "nono"})
							, #Set({left: "nono", right: "haha"})
							]
						)

						let field = res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field
						itPromise("applies last", () => {
							test()->Promise.tap(res => res->field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
						itPromise("resolves to  valid", () => {
							test()->Promise.tap(res => res->field->Subject.enum->expect->toEqual(#Valid))
						})
					})
				describe("setElement", () => {
					let l = "HEHE"
					let r = "NONO"

					let test = MkDyn.test(context,
						[ #Set({left: "haha", right: "nono"})
						, #Action( ({inner}) => inner.right.set(r) )
						, #Action( ({inner}) => inner.left.set(l) )
						]
					)

					itPromise("Applies inner set left", () => {
						test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual(l))
					})
					itPromise("Applies inner set right", () => {
						test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual(r))
					})
				})
				})
			})
		})
	})
})