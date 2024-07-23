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

module FieldString = FieldString.Make({
  let validateImmediate = true
})


describe("FieldProduct", () => {
	describe("Product2", () => {
		describe("validate immediate", () => {
			module Subject = FieldProduct.Product2.Make({
				let validateImmediate = true 
			}, Gen2, FieldString, FieldString)

			describe("context default", () => {
				let context: Subject.context = {
					inner: {
						left: { },
						right: { }
					}
				}

				describe("#Validate", () => {
					let left: FieldString.t = Valid("a", "a")
					let right: FieldString.t = Valid("b", "b")
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

							let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

							set->Rxjs.next({left: "haha", right: "nono"})
							current.contents.close()

							res
						}

						itPromise("applies value", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual({left: "haha", right: "nono"}))
						})
					})
				describe("setElement", () => {
					let test = () => {
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

						set->Rxjs.next({left: "haha", right: "nono"})
						Promise.sleep(100)
						->Promise.tap(_ => current.contents.pack.actions.inner.right.set("HEHE"))
						->Promise.delay(~ms=100)
						->Promise.tap(_ => current.contents.pack.actions.inner.left.set("NONO"))
						->Promise.delay(~ms=100)
						->Promise.tap(_ => current.contents.close())
						->Promise.void

						res
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
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

						set->Rxjs.next({left: "haha", right: "nono"})
						set->Rxjs.next({left: "nono", right: "haha"})
						Promise.sleep(100)->Promise.tap(_ => current.contents.close())->Promise.void

						itPromise("applies last", () => {
							res->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
					})
					describe("setElement", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

							set->Rxjs.next({left: "haha", right: "nono"})
							Promise.sleep(100)
							->Promise.tap(_ => current.contents.pack.actions.inner.right.set("HEHE"))
							->Promise.delay(~ms=100)
							->Promise.tap(_ => current.contents.pack.actions.inner.left.set("NONO"))
							->Promise.delay(~ms=100)
							->Promise.tap(_ => current.contents.close())
							->Promise.void

							res
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

				let validateString = (_x: FieldString.output) => {
						// Console.log2("validateString", x)
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
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

						// let hist = dyn->Dynamic.toHistory
						set->Rxjs.next({left: "haha", right: "nono"})
						set->Rxjs.next({left: "nono", right: "haha"})
						// Needs to be long enough for
						Promise.sleep(1000)->Promise.tap(_ => current.contents.close())->Promise.void

						// hist->Promise.tap(hist => {
						// 	hist->Array.map(x => x->Tuple.fst2->Form.field->Subject.show)
						// 	->Console.log2("hist", _)
						// })->Promise.void

						let field = res->Promise.map(res => res->Close.pack->Form.field)
						itPromise("applies last", () => {
							field->Promise.tap(field => field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
						itPromise("resolves to valid", () => {
							field->Promise.tap(field => field->Subject.enum->expect->toEqual(#Valid))
						})
					})
					describe("setElement", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

							set->Rxjs.next({left: "haha", right: "nono"})
							Promise.sleep(100)
							->Promise.tap(_ => current.contents.pack.actions.inner.right.set("HEHE"))
							->Promise.delay(~ms=100)
							->Promise.tap(_ => current.contents.pack.actions.inner.left.set("NONO"))
							->Promise.delay(~ms=100)
							->Promise.tap(_ => current.contents.close())
							->Promise.void

							res
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
			module Subject = FieldProduct.Product2.Make({
				let validateImmediate = false 
			}, Gen2, FieldString, FieldString);

			describe("context default", () => {
				let context: Subject.context = {
					inner: {
						left: { },
						right: { }
					}
				}

				describe("#makeDyn", () => {
					describe("setOuter", () => {
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

						set->Rxjs.next({left: "haha", right: "nono"})
						current.contents.close()

						itPromise("applies value", () => {
							res->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual({left: "haha", right: "nono"}))
						})
					})
					describe("setElement", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

							set->Rxjs.next({left: "haha", right: "nono"})
							Promise.sleep(100)
							->Promise.tap(_ => current.contents.pack.actions.inner.right.set("HEHE"))
							->Promise.delay(~ms=100)
							->Promise.tap(_ => current.contents.pack.actions.inner.left.set("NONO"))
							->Promise.delay(~ms=100)
							->Promise.tap(_ => current.contents.close())
							->Promise.void

							res
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
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

						set->Rxjs.next({left: "haha", right: "nono"})
						set->Rxjs.next({left: "nono", right: "haha"})
						Promise.sleep(100)->Promise.tap(_ => current.contents.close())->Promise.void

						itPromise("applies last", () => {
							res->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
					})
					describe("setElement", () => {
						let test = () => {
							let set = Rxjs.Subject.makeEmpty()
							let val = Rxjs.Subject.makeEmpty()

							let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
							let current: ref<'a> = {contents: first}

							let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

							set->Rxjs.next({left: "haha", right: "nono"})
							Promise.sleep(100)
							->Promise.tap(_ => current.contents.pack.actions.inner.right.set("HEHE"))
							->Promise.delay(~ms=100)
							->Promise.tap(_ => current.contents.pack.actions.inner.left.set("NONO"))
							->Promise.delay(~ms=100)
							->Promise.tap(_ => current.contents.close())
							->Promise.void

							res
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

				let validateString = (_x: FieldString.output) => {
						// Console.log2("validateString", x)
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
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

						// let hist = dyn->Dynamic.toHistory
						set->Rxjs.next({left: "haha", right: "nono"})
						set->Rxjs.next({left: "nono", right: "haha"})
						Promise.sleep(100)->Promise.tap(_ => current.contents.close())->Promise.void

						// hist->Promise.tap(hist => {
						// 	hist->Array.map(x => x->Tuple.fst2->Form.field->Subject.show)->Console.log2("hist", _)
						// })->Promise.void

						let field = res->Promise.map(res => res->Close.pack->Form.field)
						itPromise("applies last", () => {
							field->Promise.tap(field => field->Subject.input->expect->toEqual({left: "nono", right: "haha"}))
						})
						itPromise("resolves to dirty", () => {
							field->Promise.tap(field => field->Subject.enum->expect->toEqual(#Dirty))
						})
					})
				describe("setElement", () => {
					let test = () => {
						let set = Rxjs.Subject.makeEmpty()
						let val = Rxjs.Subject.makeEmpty()

						let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
						let current: ref<'a> = {contents: first}

						let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

						set->Rxjs.next({left: "haha", right: "nono"})
						Promise.sleep(100)
						->Promise.tap(_ => current.contents.pack.actions.inner.right.set("HEHE"))
						->Promise.delay(~ms=100)
						->Promise.tap(_ => current.contents.pack.actions.inner.left.set("NONO"))
						->Promise.delay(~ms=100)
						->Promise.tap(_ => current.contents.close())
						->Promise.void

						res
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