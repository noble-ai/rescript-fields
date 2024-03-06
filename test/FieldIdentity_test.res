open Vitest
// shadow global Dynamic with the impl chosen by FT
describe("FieldIdentity", () => {
  module FieldIdentity = FieldIdentity.Float
  let value = 3.0
  let input = Store.dirty(value)
  describe("#validate", () => {
    // Incredible. but an Identity field can only ever hold a value, so its always ok
    testPromise("should return Ok", () => {
      FieldIdentity.validate( false, ({}: FieldIdentity.context), input)
      ->Dynamic.toPromise
      ->Promise.tap(x => expect(x)->toEqual(Valid(value, value)))
    })
  })

  describe("#reduce", () => {
    testPromise("returns the change value", () => {
      let change = 1.0
      FieldIdentity.reduce( ~context=({}: FieldIdentity.context), Dynamic.return(input), {value: #Set(change), index: 0, priority: 0})
      ->Dynamic.toPromise
      ->Promise.tap(result => expect(result)->toEqual(Store.Valid(change, change)))
    })
  })
})
