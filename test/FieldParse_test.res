open Vitest

describe("Float", () => {
  module Subject = FieldParse.Float
  describe("#validate", () => {
    describe("empty string", () => {
      let input = ""
      let res = Subject.validate(false, {}: Subject.context, Store.Dirty(input))
      testPromise("does not parse", () => {
        res
        ->Dynamic.toPromise
        ->Promise.tap( x => {
          expect(x)->toEqual(Invalid(input, "does not parse"))
        })
      })
    })

    describe("Int", () => {
      let input = Store.Dirty("3")
      testPromise("is Valid", () => {
        Subject.validate(false, {}: Subject.context, input)
        ->Dynamic.toPromise
        ->Promise.tap( x => expect(x)->toEqual(Valid("3", 3.0)))
      })
    })

    describe("Scientific", () => {
      let input = Store.Dirty("10e3")
      testPromise("is Valid", () => {
        Subject.validate(false, {}: Subject.context, input)
        ->Dynamic.toPromise
        ->Promise.tap( x => {
          expect(x)->toEqual(Valid("10e3", 10e3))
        })
      })
    })
  })

  describe("makeDyn", () => {
    describe("context default", () => {
      let context: Subject.context = { }

      describe("setOuter", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          // close function is static in FieldParse so we can use the first one at the end
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}
          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise
          [ (.) => set->Rxjs.next("3")
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        itPromise("applies the set value", () => {
          test()->Promise.tap(x => {
            expect(x->Close.pack->Form.field)->toEqual(Store.Valid("3", 3.0))
          })
        })
      })

      describe("validateOuter", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          // close function is static in FieldParse so we can use the first one at the end
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}
          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

          [ (.) => set->Rxjs.next("3")
          , (.) => val->Rxjs.next()
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        itPromise("applies the set value", () => {
          test()->Promise.tap(res => {
            expect(res->Array.leaf->Option.getUnsafe->Close.pack->Form.field)->toEqual(Store.Valid("3", 3.0))
          })
        })
      })

      describe("set", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          // close function is static in FieldParse so we can use the first one at the end
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}
          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

          [ (.) => current.contents.pack.actions.set("3")
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        itPromise("applies the set value", () => {
          test()->Promise.tap(x => {
            expect(x.pack.field)->toEqual(Store.Valid("3", 3.0))
          })
        })
      })

      describe("clear", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          // close function is static in FieldParse so we can use the first one at the end
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}
          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise
          [ (.) => current.contents.pack.actions.set("3")
          , (.) => current.contents.pack.actions.clear()
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        itPromise("Is validated Invalid", () => {
          test()->Promise.tap(x => {
            expect(x->Close.pack->Form.field->Subject.enum)->toEqual(#Invalid)
          })
        })
      })

      describe("validateInner", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          // close function is static in FieldParse so we can use the first one at the end
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}
          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

          [ (.) => current.contents.pack.actions.set("3")
          , (.) => current.contents.pack.actions.validate()
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        itPromise("applies the set value", () => {
          test()->Promise.tap(res => {
            expect(res->Array.leaf->Option.getUnsafe->Close.pack->Form.field)->toEqual(Store.Valid("3", 3.0))
          })
        })
      })
    })

    describe("context validation", () => {
      let context: Subject.context = {
        validate: (x) => Promise.sleep(x->Int.fromFloatUnsafe)->Promise.const(Ok())
      }

      describe("race conditions", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          // close function is static in FieldParse so we can use the first one at the end
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}
          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

          [ (.) => current.contents.pack.actions.set("20")
          , (.) => current.contents.pack.actions.set("2")
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        itPromise("emits busy for both values in order", () => {
          test()->Promise.tap(res => {
            let busys = res->Array.map(x => x->Close.pack->Form.field)->Array.filter(x => x->Subject.enum == #Busy)
            [Store.Busy("20"), Store.Busy("2")]
            ->Array.forEach(busy => busys->expect->toContainEqual(busy))
          })
        })

        itPromise("ends valid for last value", () => {
          test()->Promise.tap(res => {
            let last = res->Array.leaf->Option.getUnsafe->Close.pack->Form.field
            expect(last)->toEqual(Store.Valid("2", 2.0))
          })
        })
      })
    })
  })
})

describe("FieldParse.String", () => {
  module Field = FieldParse.String.Field
	describe("context default", () => {
		let context: Field.context = {}
		describe("makeDyn", () => {
			describe("reset", () => {
				let test = () => {
					let set = Rxjs.Subject.makeEmpty()
					let val = Rxjs.Subject.makeEmpty()
					let {first, init, dyn} = Field.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
					let current: ref<'a> = {contents: first}
					let res =
            Rxjs.concatArray(
              [ Dynamic.return(init)
              // , dyn
              ]
            )
            ->Dynamic.switchSequence
            ->Current.apply(current)
            ->Dynamic.toHistory

          [ (.) => current.contents.pack.actions.reset()
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
				}

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
		describe("reset", () => {
			let test = () => {
				let set = Rxjs.Subject.makeEmpty()
				let val = Rxjs.Subject.makeEmpty()
				let {first, dyn} = Field.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
					let current: ref<'a> = {contents: first}
				let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

        [ (.) => current.contents.pack.actions.validate()
        , (.) => current.contents.pack.actions.reset()
        , (.) => current.contents.close()
        ]
        ->Test.chain(~delay=500)
        ->Promise.bind(_ => res)
			}

			itPromise("ends valid", () => {
				test()->Promise.tap( res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Field.enum->expect->toEqual(#Valid))
			})

		})
		describe("set", () => {
			let value = "test"
			let test = () => {
				let set = Rxjs.Subject.makeEmpty()
				let val = Rxjs.Subject.makeEmpty()

				let {first, dyn} = Field.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
					let current: ref<'a> = {contents: first}
				let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

        [ (.) => current.contents.pack.actions.validate()
        , (.) => current.contents.pack.actions.set(value)
        , (.) => current.contents.close()
        ]
        ->Test.chain(~delay=500)
        ->Promise.bind(_ => res)
			}
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
				test()->Promise.tap( res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Field.input->expect->toEqual(value))
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
				let {first, dyn} = Field.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
					let current: ref<'a> = {contents: first}
				let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

        [ (.) => current.contents.pack.actions.validate()
        , (.) => current.contents.pack.actions.set(slow)
        , (.) => current.contents.pack.actions.set(fast)
        , (.) => current.contents.close()
        ]
        ->Test.chain(~delay=500)
        ->Promise.bind(_ => res)
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