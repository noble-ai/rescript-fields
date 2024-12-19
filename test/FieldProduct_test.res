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
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=500)
							->Promise.bind(_ => res)
						}

						itPromise("applies value", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual({left: "haha", right: "nono"}))
						})
					})
				describe("setElement", () => {
					let test = () => {
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

						[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
						, (.) => current.contents.pack.actions.inner.right.set("HEHE")
						, (.) => current.contents.pack.actions.inner.left.set("NONO")
						, (.) => current.contents.close()
						]
						->Test.chain(~delay=100)
						->Promise.bind(_ => res)
					}

					itPromise("Applies inner set left", () => {
						test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual("NONO"))
					})
					itPromise("Applies inner set right", () => {
						test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual("HEHE"))
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
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise
							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => set->Rxjs.next({left: "nono", right: "haha"})
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=100)
							->Promise.bind(_ => res)
						}

						itPromise("applies last", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
					})
					describe("setElement", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => current.contents.pack.actions.inner.right.set("HEHE")
							, (.) => current.contents.pack.actions.inner.left.set("NONO")
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=100)
							->Promise.bind(_ => res)
						}

						itPromise("Applies inner set left", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual("NONO"))
						})
						itPromise("Applies inner set right", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual("HEHE"))
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
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => set->Rxjs.next({left: "nono", right: "haha"})
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=100)
							->Promise.bind(_ => res)
						}

						let field = Promise.map(_, res => res->Close.pack->Form.field)
						itPromise("applies last", () => {
							test()->field->Promise.tap(field => field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
						itPromise("resolves to valid", () => {
							test()->field->Promise.tap(field => field->Subject.enum->expect->toEqual(#Valid))
						})
					})
					describe("setElement", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise
							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => current.contents.pack.actions.inner.right.set("HEHE")
							, (.) => current.contents.pack.actions.inner.left.set("NONO")
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=100)
							->Promise.bind(_ => res)
						}

						itPromise("Applies inner set left", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual("NONO"))
						})
						itPromise("Applies inner set right", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual("HEHE"))
						})
					})
			})
		})
		})

		describe("validate deferred", () => {
			module Subject = FieldProduct.Product2.Make(Gen2, FieldParse.String.Field, FieldParse.String.Field);

			describe("context default", () => {
				let context: Subject.context = {
					inner: {
						left: { },
						right: { }
					}
				}

				describe("#makeDyn", () => {
					describe("setOuter", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=500)
							->Promise.bind(_ => res)
						}

						itPromise("applies value", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual({left: "haha", right: "nono"}))
						})
					})
					describe("setElement", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => current.contents.pack.actions.inner.right.set("HEHE")
							, (.) => current.contents.pack.actions.inner.left.set("NONO")
							, (.) =>  current.contents.close()
							]
							->Test.chain(~delay=100)
							->Promise.bind(_ => res)
						}

						itPromise("Applies inner set left", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual("NONO"))
						})
						itPromise("Applies inner set right", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual("HEHE"))
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
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => set->Rxjs.next({left: "nono", right: "haha"})
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=100)
							->Promise.bind(_ => res)
						}

						itPromise("applies last", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
					})
					describe("setElement", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							, (.) => current.contents.pack.actions.inner.right.set("HEHE")
							, (.) => current.contents.pack.actions.inner.left.set("NONO")
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=100)
							->Promise.bind(_ => res)
						}

						itPromise("Applies inner set left", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual("NONO"))
						})
						itPromise("Applies inner set right", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual("HEHE"))
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
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise
							[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
							,(.) => set->Rxjs.next({left: "nono", right: "haha"})
							, (.) => current.contents.close()
							]
							->Test.chain(~delay=100)
							->Promise.bind(_ => res)
						}

						let field = Promise.map(_, res => res->Close.pack->Form.field)
						itPromise("applies last", () => {
							test()->field->Promise.tap(field => field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
						itPromise("resolves to  valid", () => {
							test()->field->Promise.tap(field => field->Subject.enum->expect->toEqual(#Valid))
						})
					})
				describe("setElement", () => {
					let test = () => {
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

						[ (.) => set->Rxjs.next({left: "haha", right: "nono"})
						, (.) => current.contents.pack.actions.inner.right.set("HEHE")
						, (.) => current.contents.pack.actions.inner.left.set("NONO")
						, (.) => current.contents.close()
						]
						->Test.chain(~delay=100)
						->Promise.bind(_ => res)
					}

					itPromise("Applies inner set left", () => {
						test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.left->expect->toEqual("NONO"))
					})
					itPromise("Applies inner set right", () => {
						test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->Gen2.right->expect->toEqual("HEHE"))
					})
				})
				})
			})
		})
	})
})