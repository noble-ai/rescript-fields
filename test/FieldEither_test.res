open Vitest

module FieldLeft = FieldParse.Float
module FieldRight = FieldIdentity.Int
module Subject = FieldEither.Either2.Make(
  FieldLeft,
  FieldRight,
)

describe("FieldEither", () => {
  describe("Either2", () => {
    describe("init", () =>{
      describe( "with empty context", () => {
        let context: Subject.context = {inner: ({}, ({}, ()))}
				describe("#makeDyn", () => {
					describe("setOuter", () => {
            let test = (value) => {
              let set = Rxjs.Subject.makeEmpty()
              let validate = Rxjs.Subject.makeEmpty()
              let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
              let current: ref<'a> = {contents: first}

              let res = dyn
                ->Dynamic.switchSequence
                ->Current.apply(current)
                ->Dynamic.toHistory

              [ (.) => Rxjs.next(set, value)
              , (.) => current.contents.close()
              ]
              ->Test.chain(~delay=100)
              ->Promise.bind(_ => res)
            }

						itPromise("applys value", () => {
              let value = Either.Left("3")
							test(value)->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual(value))
						})
					})

          describe("opt", () => {
            describe("some", () => {
              let value = Either.Right(Either.Left(4))
              let test = () => {
                let set = Rxjs.Subject.makeEmpty()
                let validate = Rxjs.Subject.makeEmpty()

                let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
              let current: ref<'a> = {contents: first}

                let res = dyn->Dynamic.switchSequence
                ->Current.apply(current)
                ->Dynamic.toPromise

                [ (.) => Rxjs.next(set, Either.Left("3"))
                , (.) => current.contents.pack.actions.opt(Some(value))
                , (.) => current.contents.close()
                ]
                ->Test.chain(~delay=100)
                ->Promise.bind(_ => res)
              }

              itPromise("sets value", () => {
                test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(value))
              })
            })

            describe("none", () => {
              let test = () => {
                let set = Rxjs.Subject.makeEmpty()
                let validate = Rxjs.Subject.makeEmpty()
                let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
                let current: ref<'a> = {contents: first}

                let res = dyn
                ->Dynamic.switchSequence
                ->Current.apply(current)
                ->Dynamic.toPromise

                [ (.) => Rxjs.next(set, Either.Left("3"))
                , (.) => current.contents.pack.actions.opt(None)
                , (.) => current.contents.close()
                ]
                ->Test.chain(~delay=100)
                ->Promise.bind(_ => res)
              }

              itPromise("clears value", () => {
                test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->not->toEqual(Either.Left("3")))
              })
            })
          })
				})
      })

      describe( "context validation inner", () => {
        let context = (): Subject.context => {
          let delay: ref<int> = {contents: 100}

          // Each validation is a bit quicker than the last so the responses come back out of order
          // let validateString = (_x: FieldRight.output) => {
          //     let d = delay.contents
          //     delay.contents = delay.contents - 10
          //     Promise.sleep(d)->Promise.map(_ => Ok())
          //   }
          let validateFloat = (_x: FieldLeft.output) => {
              let d = delay.contents
              delay.contents = delay.contents - 10
              Promise.sleep(d)->Promise.map(_ => Ok())
            }

          {inner: ({validate: validateFloat}, ({}, ()))}
        }

				describe("#makeDyn", () => {
					describe("setOuter", () => {
            let values: Array.t<Subject.input> = [Either.Left("1"), Either.Right(Either.Left((2))), Either.Left("3")]
            let test = () => {
              let set = Rxjs.Subject.makeEmpty()
              let validate = Rxjs.Subject.makeEmpty()
              let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
                let current: ref<'a> = {contents: first}

              let res = dyn
                ->Dynamic.switchSequence
                ->Current.apply(current)
                ->Dynamic.toPromise

              [ (.) => values->Array.forEach(Rxjs.next(set))
              , (.) => current.contents.close()
              ]
              ->Test.chain(~delay=100)
              ->Promise.bind(_ => res)
            }

						itPromise("applys last value", () => {
							test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(values->Array.leaf->Option.getUnsafe))
						})
					})

          describe("clear", () => {
            let test = () => {
              let set = Rxjs.Subject.makeEmpty()
              let validate = Rxjs.Subject.makeEmpty()
              let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
                let current: ref<'a> = {contents: first}
              let res = dyn
              ->Dynamic.switchSequence
              ->Current.apply(current)
              ->Dynamic.toPromise

              [ (.) => Rxjs.next(set, Either.Left("3"))
              , (.) => current.contents.pack.actions.clear()
              , (.) => current.contents.close()
              ]
              ->Test.chain(~delay=100)
              ->Promise.bind(_ => res)
            }

            itPromise("clears", () => {
              test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->not->toEqual(Either.Left("3")))
            })
          })

          describe("validate", () => {
            let test = () => {
              let set = Rxjs.Subject.makeEmpty()
              let validate = Rxjs.Subject.makeEmpty()
              let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
                let current: ref<'a> = {contents: first}
              let res = dyn
              ->Dynamic.switchSequence
              ->Current.apply(current)
              ->Dynamic.toHistory

              [ (.) => Rxjs.next(set, Either.Left("3"))
              , (.) => current.contents.pack.actions.validate()
              , (.) => current.contents.close()
              ]
              ->Test.chain(~delay=100)
              ->Promise.bind(_ => res)
            }

            itPromise("sets inner value", () => {
              test()->Promise.tap(res => {
                res
                ->Array.leaf
                ->Option.getUnsafe
                ->Close.pack
                ->Form.field
                ->Subject.input
                ->expect->toEqual(Either.Left("3"))
              })
            })

          })
          describe("opt", () => {
           describe("some", () => {
              let value = Either.Right(Either.Left(4))
              let test = () => {
                let set = Rxjs.Subject.makeEmpty()
                let validate = Rxjs.Subject.makeEmpty()
                let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
                let current: ref<'a> = {contents: first}
                let res = dyn
                ->Dynamic.switchSequence
                ->Current.apply(current)
                ->Dynamic.toPromise

                [ (.) => Rxjs.next(set, Either.Left("3"))
                , (.) => current.contents.pack.actions.opt(Some(value))
                , (.) => current.contents.close()
                ]
                ->Test.chain(~delay=100)
                ->Promise.bind(_ => res)
              }

              itPromise("sets value", () => {
                test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(value))
              })
            })

            describe("none", () => {
              let test = () => {
                let set = Rxjs.Subject.makeEmpty()
                let validate = Rxjs.Subject.makeEmpty()
                let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
                let current: ref<'a> = {contents: first}
                let res = dyn
                ->Dynamic.switchSequence
                ->Current.apply(current)
                ->Dynamic.toPromise

                [ (.) => Rxjs.next(set, Either.Left("3"))
                , (.) => current.contents.pack.actions.opt(None)
                , (.) => current.contents.close()
                ]
                ->Test.chain(~delay=100)
                ->Promise.bind(_ => res)
              }

              itPromise("clears value", () => {
                test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->not->toEqual(Either.left("3")))
              })
            })
          })

          describe("inner", () => {
            let test =  () => {
              let set = Rxjs.Subject.makeEmpty()
              let validate = Rxjs.Subject.makeEmpty()
              let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
              let current: ref<'a> = {contents: first}
              let res = dyn
              ->Dynamic.switchSequence
              ->Current.apply(current)
              ->Dynamic.toPromise

              let left = ((left, _)) => left
              let right = ((_, (right, _))) => right

              [ (.) => Rxjs.next(set, Either.Left("3"))
              , (.) => left(current.contents.pack.actions.inner).set("2")
              , (.) => right(current.contents.pack.actions.inner).set(5)
              , (.) => current.contents.close()
              ]
              ->Test.chain(~delay=100)
              ->Promise.bind(_ => res)
            }

            itPromise("sets inner value", () => {
              test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(Either.Right(Either.Left(5))))
            })
          })
        })
      })
    })
  })
})
