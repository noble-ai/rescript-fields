open Jest

describe("FieldIdentity", () => {
  module FieldIdentity = FieldIdentity.Float
  let value = 3.0
  let input = Store.dirty(value)
  describe("#validate", () => {
    // Incredible. but an Identity field can only ever hold a value, so its always ok
    testDone("should return Ok", (success, _failure) => {
      FieldIdentity.validate(
        false,
        ({}: FieldIdentity.context),
        input,
      )->Dynamic.finally(x => {
        expect(x)->toEqual(Valid(value, value))
        success()
      })
    })
  })

  describe("#reduce", () => {
    testDone("returns the change value", (success, _failure) => {
      let change = 1.0
      FieldIdentity.reduce(
        ~context=({}: FieldIdentity.context),
        Dynamic.return(input),
        #Set(change),
      )->Dynamic.finally(result => {
        expect(result)->toEqual(Store.Valid(change, change))
        success()
      })
    })
  })
})
