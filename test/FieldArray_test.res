open Vitest
// shadow global Dynamic with the impl chosen by FT
open! FieldTrip

describe("FieldArray", () => {
  module FieldElement = FieldOpt.Int
  module FieldArray = FieldArray.Make(
  (F: Field) => {
    let filter = FieldArray.filterIdentity
    let empty = _ => []
    let validateImmediate = true
  }
  , FieldElement
  )

  let context: FieldArray.context = {element: {}}
  // let context = context->Dynamic.return

  describe("#makeStore", () => {
    describe("empty", () => {
      let result = FieldArray.makeStore(~context,[])->Dynamic.toPromise
      testPromise("returns Valid", () => {
        result->Promise.map( result => expect(result)->toEqual(Valid([], [])) )
      })
    })

    describe("some invalid", () => {
      let result = FieldArray.makeStore(~context,[Valid(Some(Store.Valid("33", 33)), 33), Invalid(None, #Part)])->Dynamic.toPromise
      testPromise("returns invalid", () => {
        result->Promise.map( result => expect(result->Store.toEnum)->toEqual(#Invalid) )
      })
    })
  })

  describe("#validateImpl", () => {
    describe("with an async validate", () => {
        let validate = (_) => Result.return()->Promise.return
        let valid = [3]
        let input = valid->Array.map(x => Store.Valid(Some(Store.Valid(x->Int.toString, x)), x))
        let res = FieldArray.validateImpl({ validate, element: {} }, false, input)
        it("returns Ok", () => {
          expect(res->Result.isOk)->toBe(true)
        })
        res
        ->Result.toOption
        ->Option.map( res => {
          itPromise("emits Busy, then valid", () => {
            res->Dynamic.toHistory->Promise.tap( h => h->Array.map(Store.toEnum)->expect->toEqual([#Busy, #Valid]))
          })
        })
        ->Option.void
    })
  })

  describe("#validate", () => {
    describe("empty", () => {
      testPromise("returns Ok", () => {
        FieldArray.validate(false, context, Dirty([]))
        ->Dynamic.toPromise
        ->Promise.tap(result => {
          expect(result)->toEqual(Valid([], []))
        })
      })
    })

    describe("non-empty", () => {
      describe("all valid", () => {
        let valid = [3, 4, 5]
        let input = valid->Array.map(x => Store.Dirty(Some(Store.Dirty(x->Int.toString))))
        describe("without external validation", () =>  {
          testPromise("returns Ok", () => {
            FieldArray.validate(false, context, Dirty(input))
            ->Dynamic.toPromise
            ->Promise.tap(result => {
              let output = result->FieldArray.output
              expect(output)->toEqual(Some(valid))
            })
          })
        })

        describe("with external validation, failing", () => {
          describe("fails constantly", () => {
            let message =  "Fails"
            let validate = (_arr) => Result.Error(message)->Promise.return
            let context: FieldArray.context = {validate, element: {}}
            let validated = FieldArray.validate(false, context, Dirty(input))
            let history = validated->Dynamic.toHistory
            testPromise("returns atleast one state", () => {
              history
              ->Promise.tap(x => x->Array.length->expect->toBeGreaterThanInt(0))
            })
            testPromise("begins With Busy", () => {
              history
              ->Promise.tap(result => expect(result->Array.getUnsafe(0)->FieldArray.enum)->toEqual(#Busy))
            })
            testPromise("returns Error", () => {
              history
              ->Promise.map(r => r->Array.leaf->Option.getExn(~desc="") )
              ->Promise.tap(result =>
                expect(result->FieldArray.error)->toEqual(Some(#Whole(message)))
              )
            })
          })

          describe("example considering array values", () => {
            let message = "Elements must Sum to 100"
            let validate = (arr) => arr->Array.reduce((a,b) => a+b, 0)->Some->Option.guard(x => x == 100)->Result.fromOption(message)->Result.const()->Promise.return
            let context: FieldArray.context = {validate, element: {}}
            testPromise("returns Error", () => {
              FieldArray.validate(false, context, Dirty(input))
              ->Dynamic.toPromise
              ->Promise.tap(result => {
                expect(result->FieldArray.error)->toEqual(Some(#Whole(message)))
              })
            })
          })
        })
      })

      describe("some valid", () => {
        let indexBad = 1
        let bad = None
        let good = [Some(3), Some(5)]
        let input = good->Array.insert(bad, indexBad)->Array.map(x => x->Option.map(Int.toString)->FieldElement.set)->Store.Dirty

        let result = FieldArray.validate(false, context, input)
        testPromise("returns partial Error", () => {
          result->Dynamic.toPromise
          ->Promise.tap(result => {
            expect(result->FieldArray.error)->toEqual(Some(#Part))
          })
        })
      })
    })
  })

  describe("#reduce", () => {
    let input = [Some(3), None]
    let store = input->Array.map(Option.map(_, Int.toString))->FieldArray.set->Dynamic.return
    describe("#Set", () => {
      describe("with some unset opt ints", () => {
        let new = [None, None, Some(666)]
        let change = #Set(new->Array.map(Option.map(_, Int.toString)))
        let result = FieldArray.reduce(~context, store, {value: change, index: 0, priority: 0})
        testPromise("returns Dirty", () => {
          // A FieldOpt set to None is considered dirty, since FieldOpt requires the value be set to be
          // considered.  We then prefer dirty over invalid. More of a test of FieldOpt.Int but ok.
          result->Dynamic.toPromise
          ->Promise.tap(result => {
            expect(result->Store.toEnum)->toEqual(#Dirty)
          })
        })
      })
      // test("returns new value", () => {
      //   expect(result)->toEqual(new)
      // })
    })

    describe("#Clear", () => {
      let change = #Clear
      let result = FieldArray.reduce(~context, store, {value: change, index: 0, priority: 0})
      testPromise("returns empty", () => {
        result
        ->Dynamic.toPromise
        ->Promise.tap(result => {
          expect(result)->toEqual(Valid([], []))
        })
      })
    })

    describe("#Add", () => {
      let new = Some(666)
      let change = #Add(#Some(new->Option.map(Int.toString)))
      let result = FieldArray.reduce(~context, store, {value: change, index: 0, priority: 0})
      let innerstore = result->Dynamic.map(Store.inner)

      testPromise("increases length by 1", () => {
        innerstore
        ->Dynamic.toPromise
        ->Promise.tap(innerstore =>{
          expect(innerstore->Array.length)->toEqual(input->Array.length + 1)
        })
      })

      testPromise("appends new value ", () => {
        innerstore
        ->Dynamic.map(innerstore => Array.getUnsafe(innerstore, innerstore->Array.length - 1))
        ->Dynamic.toPromise
        ->Promise.tap(last => {
          expect(last->FieldElement.input)->toEqual(new->Option.map(x => x->Int.toString))
        })
      })

      testPromise("leaves prefix unmodified", () => {
        innerstore->Dynamic.toPromise->Promise.tap(innerstore => {
          let prefix = innerstore->Array.slice(0, innerstore->Array.length - 1)
          expect(prefix)->toEqual(input->Array.map(x => x->Option.map(Int.toString)->FieldElement.set))
        })
      })
    })

    describe("#Index", () => {
      describe("simple", () => {
        let new = 666
        let index = 1
        let change = #Index(index, #Some(#Set(new->Int.toString)))
        let result = FieldArray.reduce(~context, store, {value: change, index: 0, priority: 0})
        let innerstore = result->Dynamic.map(Store.inner)
        testPromise("returns new value", () => {
          innerstore->Dynamic.toPromise->Promise.tap(innerstore => {
            expect(innerstore->Array.getUnsafe(index))->toEqual(
              Valid(Some(Valid(new->Int.toString, new)), new),
            )
          }
          )
        })
      })
    })

    describe("#Remove", () => {
      describe("out of bounds", () => {
        let index = 5
        let change = #Remove(index)
        let result = FieldArray.reduce(~context, store, {value: change, index: 0, priority: 0})
        testPromise("returns input", () => {
          result->Dynamic.toPromise
          ->Promise.tap(result => {
            expect(result->FieldArray.input)->toEqual(input->Array.map(Option.map(_, Int.toString)))
          })
        })
      })

      describe("in bounds", () => {
        let index = 1
        let change = #Remove(index)
        let result = FieldArray.reduce(~context, store, {value: change, index: 0, priority: 0})
        testPromise("decreases array length by 1", () => {
          result->Dynamic.toPromise
          ->Promise.tap(result => {
            let inner = result->Store.inner
            expect(inner->Array.length)->toEqual(input->Array.length - 1)
          })
        })
        // TODO check other elements
      })
    })
  })
})
