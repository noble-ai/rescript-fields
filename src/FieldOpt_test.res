open Jest

describe("FieldOpt", () => {
  module FieldOpt = FieldOpt.Int
  describe("#validate", () => {
    describe("None", () => {
      let input = None
      testDone("Fails with required", (success, _fail) => {
        FieldOpt.validate(false, {} : FieldOpt.context, Dirty(input))
        ->Dynamic.finally( x => {
          expect(x)->toEqual(Invalid(input, #Whole("Required")))
          success()
        })
      })
    })

    describe("Some", () => {
      let input = Store.Dirty(Some(Store.Dirty("3")))
      testDone("Fails with required", (success, _fail) => {
        FieldOpt.validate(false, {}:FieldOpt.context, input)
        ->Dynamic.finally( x => {
          expect(x)->toEqual(Valid(Some(Valid("3", 3)), 3))
          success()
        })
      })
    })
  })
  // TODO reduce - AxM
})
