open Vitest
describe("FieldIdentity", () => {
  module Subject = FieldIdentity.Float
  module MkDyn = Test.MkDyn(Subject)
  let value = 3.0
  let input = Store.dirty(value)
  describe("#validate", () => {
    // Incredible. but an Identity field can only ever hold a value, so its always ok
    testPromise("should return Ok", () => {
      Subject.validate( false, ({}: Subject.context), input)
      ->Dynamic.toPromise
      ->Promise.tap(x => expect(x)->toEqual(Valid(value, value)))
    })
  })

  describe("#makeDyn", () => {
    describe("context empty", () => {
      let context: Subject.context = {}

      describe("#default", () => {
        let test = MkDyn.test(context,
          [
          ]
        )

        testPromise("emits a single value", () => {
          test()->Promise.tap(result => {
            result->expect->toHaveLengthArray(1)
          })
        })
      })

      describe("#setOuter", () => {
        let test = MkDyn.test(context,
          [ #Set(3.0)
          ]
        )

        testPromise("returns the change value", () => {
          test()->Promise.tap(result => result->Array.leaf->Option.getUnsafe->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })

      describe("#set", () => {
        let test = MkDyn.test(context,
          [ #Set(3.0)
          ]
        )

        testPromise("returns the change value", () => {
          test()->Promise.tap(result => result->Array.leaf->Option.getUnsafe->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })

      describe("#validateOuter", () => {
        let test = MkDyn.test(context,
          [ #Set(3.0)
          , #Validate
          ]
        )

        testPromise("emits a new value for each action", () => {
          test()->Promise.tap(result => {
            result->expect->toHaveLengthArray(3)
          })
        })

        testPromise("returns the change value", () => {
          test()->Promise.tap(result => result->Array.leaf->Option.getUnsafe->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })

      describe("#clear", () => {
        let test = MkDyn.test(context,
          [ #Action( ({set}) => set(3.0) )
          , #Action( ({clear}) => clear() )
          ]
        )

        testPromise("returns the empty value", () => {
          test()->Promise.tap(result => result->Array.leaf->Option.getUnsafe->Close.pack->Form.field->expect->toEqual(Store.Valid(0., 0.)))
        })
      })

      describe("#opt", () => {
        [("None", None, 0.0), ("Some(4.0)", Some(4.0), 4.0)]
        ->Array.forEach( ((name, value, out)) => {
          describe(name, () => {
            let test = MkDyn.test(context,
              [ #Action( ({set}) => set(3.0) )
              , #Action( ({opt}) => opt(value) )
              ]
            )

            testPromise("returns the expected value", () => {
              test()->Promise.tap(result => result->Array.leaf->Option.getUnsafe->Close.pack->Form.field->expect->toEqual(Store.Valid(out, out)))
            })
          })
        })
      })
    })
  })
})
