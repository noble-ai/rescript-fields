open Vitest

module FieldLeft = FieldParse.Float
module FieldRight = FieldIdentity.Int
module Subject = FieldEither.Either2.Make(
  FieldLeft,
  FieldRight,
)
module MkDyn = Test.MkDyn(Subject)

describe("FieldEither", () => {
  describe("Either2", () => {
    describe("init", () =>{
      describe( "with empty context", () => {
        let context: Subject.context = {inner: ({}, ({}, ()))}
				describe("#makeDyn", () => {
					describe("setOuter", () => {
            let test = (value) =>
              MkDyn.test(context,
                [ #Set(value)
                ]
              )()

						itPromise("applys value", () => {
              let value = Either.Left("3")
							test(value)->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual(value))
						})
					})

          describe("opt", () => {
            describe("some", () => {
              let value = Either.Right(Either.Left(4))
              let test = MkDyn.test(context,
                [ #Set(Either.Left("3"))
                , #Action( ({opt}) => opt(Some(value)) )
                ]
              )

              itPromise("sets value", () => {
                test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual(value))
              })
            })

            describe("none", () => {
              let test = MkDyn.test(context,
                [ #Set(Either.Left("3"))
                , #Action( ({opt}) => opt(None) )
                ]
              )

              itPromise("clears value", () => {
                test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->not->toEqual(Either.Left("3")))
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
            let test = MkDyn.test(context(),
              values->Array.map( (v) => #Set(v) )
            )

						itPromise("applys last value", () => {
							test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual(values->Array.leaf->Option.getUnsafe))
						})
					})

          describe("clear", () => {
            let test = MkDyn.test(context(),
              [ #Set(Either.Left("3"))
              , #Action( ({clear}) => clear() )
              ]
            )

            itPromise("clears", () => {
              test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->not->toEqual(Either.Left("3")))
            })
          })

          describe("validate", () => {
            let test = MkDyn.test(context(),
              [ #Set(Either.Left("3"))
              , #Action( ({validate}) => validate() )
              ]
            )

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
              let test = MkDyn.test(context(),
                [ #Set(Either.Left("3"))
                , #Action( ({opt}) => opt(Some(value)) )
                ]
              )

              itPromise("sets value", () => {
                test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual(value))
              })
            })

            describe("none", () => {
              let test = MkDyn.test(context(),
                [ #Set(Either.Left("3"))
                , #Action( ({opt}) => opt(None) )
                ]
              )

              itPromise("clears value", () => {
                test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->not->toEqual(Either.left("3")))
              })
            })
          })

          describe("inner", () => {
            let left = ((left, _)) => left
            let right = ((_, (right, _))) => right

            let test = MkDyn.test(context(),
              [ #Set(Either.Left("3"))
              , #Action( ({inner}) => left(inner).set("2") )
              , #Action( ({inner}) => right(inner).set(5) )
              ]
            )

            itPromise("sets inner value", () => {
              test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual(Either.Right(Either.Left(5))))
            })
          })
        })
      })
    })
  })
})
