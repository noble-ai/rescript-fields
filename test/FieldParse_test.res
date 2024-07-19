open Vitest
// shadow global Dynamic with the impl chosen by FT

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
          expect(x)->toEqual(Invalid(input, #DoesNotParse))
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
      let context: Subject.context = {}

      describe("setOuter", () => {
        let set = Rxjs.Subject.makeEmpty()
        let val = Rxjs.Subject.makeEmpty()
        // close function is static in FieldParse so we can use the first one at the end
        let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}
        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

        set->Rxjs.next("3")
        current.contents.close()
        itPromise("applies the set value", () => {
          res->Promise.tap(x => {
            expect(x->Close.pack->Form.field)->toEqual(Store.Valid("3", 3.0))
          })
        }) 
      })

      describe("validateOuter", () => {
        let set = Rxjs.Subject.makeEmpty()
        let val = Rxjs.Subject.makeEmpty()
        // close function is static in FieldParse so we can use the first one at the end
        let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}
        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

        set->Rxjs.next("3")
        val->Rxjs.next()
        current.contents.close()
        itPromise("emits a value for the validation", () => { 
          res->Promise.tap(result => result->expect->toHaveLengthArray(2))
        })
        itPromise("applies the set value", () => {
          res->Promise.tap(res => {
            expect(res->Array.leaf->Option.getUnsafe->Close.pack->Form.field)->toEqual(Store.Valid("3", 3.0))
          })
        }) 
      })

      describe("set", () => {
        let set = Rxjs.Subject.makeEmpty()
        let val = Rxjs.Subject.makeEmpty()
        // close function is static in FieldParse so we can use the first one at the end
        let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}
        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

        current.contents.pack.actions.set("3")
        current.contents.close()

        itPromise("applies the set value", () => {
          res->Promise.tap(x => {
            expect(x.pack.field)->toEqual(Store.Valid("3", 3.0))
          })
        })
      })

      describe("clear", () => {
        let set = Rxjs.Subject.makeEmpty()
        let val = Rxjs.Subject.makeEmpty()
        // close function is static in FieldParse so we can use the first one at the end
        let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}
        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise
        current.contents.pack.actions.set("3")
        current.contents.pack.actions.clear()
        current.contents.close()

        itPromise("leaves in init state", () => {
          res->Promise.tap(x => {
            expect(x->Close.pack->Form.field->Subject.enum)->toEqual(#Init)
          })
        })
      })

      describe("validateInner", () => {
        let set = Rxjs.Subject.makeEmpty()
        let val = Rxjs.Subject.makeEmpty()
        // close function is static in FieldParse so we can use the first one at the end
        let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}
        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

        current.contents.pack.actions.set("3")
        current.contents.pack.actions.validate()
        current.contents.close()

        itPromise("emits a value for the validation", () => { 
          res->Promise.tap(result => result->expect->toHaveLengthArray(2))
        })

        itPromise("applies the set value", () => {
          res->Promise.tap(res => {
            expect(res->Array.leaf->Option.getUnsafe->Close.pack->Form.field)->toEqual(Store.Valid("3", 3.0))
          })
        }) 
      })
    })
     
    describe("context validation", () => {
      let context: Subject.context = {
        validate: (x) => Promise.sleep(x->Int.fromFloatUnsafe)->Promise.const(Ok(x))
      }

      describe("race conditions", () => {
        let set = Rxjs.Subject.makeEmpty()
        let val = Rxjs.Subject.makeEmpty()
        // close function is static in FieldParse so we can use the first one at the end
        let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}
        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

        current.contents.pack.actions.set("20")
        current.contents.pack.actions.set("2")
        // Needs delay for validations to complete
        Promise.sleep(200)->Promise.tap(_ => current.contents.close())->Promise.void

        itPromise("emits busy for both values in order", () => {
          res->Promise.tap(res => {
            let busys = res->Array.map(x => x->Close.pack->Form.field)->Array.filter(x => x->Subject.enum == #Busy)
            busys->expect->toHaveLengthArray(2)
            busys->expect->toEqual([Store.Busy("20"), Store.Busy("2")])
          })
        })

        itPromise("ends valid for last value", () => {
          res->Promise.tap(res => {
            let last = res->Array.leaf->Option.getUnsafe->Close.pack->Form.field
            expect(last)->toEqual(Store.Valid("2", 2.0))
          })
        })
      })
    })
  })
})
