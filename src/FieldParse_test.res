open Jest
describe("FieldFloat", () => {
  module Field = FieldParse.Float
  describe("#validate", () => {
    describe("does not parse", () => {
      let input = ""
      testDone("Fails with empty", (success, _fail) => {
        Field.validate(false, {}: Field.context, Dirty(input))
        ->Dynamic.finally( x => {
          expect(x)->toEqual(Invalid(input, #DoesNotParse))
          success()
        })
      })
    })

    describe("Int", () => {
      let input = Store.Dirty("3")
      testDone("is Valid", (success, _fail) => {
        Field.validate(false, {}: Field.context, input)
        ->Dynamic.finally( x => {
          expect(x)->toEqual(Valid("3", 3.0))
          success()
        })
      })
    })

    describe("Scientific", () => {
      let input = Store.Dirty("10e3")
      testDone("is Valid", (success, _fail) => {
        Field.validate(false, {}: Field.context, input)
        ->Dynamic.finally( x => {
          expect(x)->toEqual(Valid("10e3", 10e3))
          success()
        })
      })
    })
  })
})
