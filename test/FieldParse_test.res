open Vitest
// shadow global Dynamic with the impl chosen by FT

describe("FieldFloat", () => {
  module Field = FieldParse.Float
  describe("#validate", () => {
    describe("empty string", () => {
      let input = ""
      let res = Field.validate(false, {}: Field.context, Store.Dirty(input))
      testPromise("does not parse", () => {
        res
        ->Dynamic.toPromise
        ->Promise.tap( x => {
          expect(x)->toEqual(Invalid(input, #DoesNotParse))
        })
      })
    })

    describe("Int", () => {
      let input = Store.Dirty("3")
      testPromise("is Valid", () => {
        Field.validate(false, {}: Field.context, input)
        ->Dynamic.toPromise
        ->Promise.tap( x => expect(x)->toEqual(Valid("3", 3.0))
        )
      })
    })

    describe("Scientific", () => {
      let input = Store.Dirty("10e3")
      testPromise("is Valid", () => {
        Field.validate(false, {}: Field.context, input)
        ->Dynamic.toPromise
        ->Promise.tap( x => {
          expect(x)->toEqual(Valid("10e3", 10e3))
        })
      })
    })
  })
})
