open Vitest
// shadow global Dynamic with the impl chosen by FT
open! FieldTrip

describe("FieldOpt", () => {
  module FieldOpt = FieldOpt.Int
  describe("#validate", () => {
    describe("None", () => {
      let input = None
      testPromise("Fails with required", () => {
        FieldOpt.validate(false, {} : FieldOpt.context, Dirty(input))
        ->Dynamic.toPromise
        ->Promise.tap( x => {
          expect(x)->toEqual(Invalid(input, #Whole("Required")))
        })
      })
    })

    describe("Some", () => {
      let input = Store.Dirty(Some(Store.Dirty("3")))
      testPromise("Fails with required", () => {
        FieldOpt.validate(false, {}:FieldOpt.context, input)
        ->Dynamic.toPromise
        ->Promise.tap( x => expect(x)->toEqual(Valid(Some(Valid("3", 3)), 3))
        )
      })
    })
  })
  // TODO reduce - AxM
})
