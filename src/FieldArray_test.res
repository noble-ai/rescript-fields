open Jest

describe("FieldArray", () => {
  module FieldElement = FieldOpt.Int
  module FieldArray = FieldArray.Make(
  (F: FieldTrip.Field) => {
    let filter = FieldArray.filterIdentity
    let empty = _ => []
  }
  , FieldElement
  )

  let context: FieldArray.context = {lengthMin: None, element: {}}
  // let context = context->Dynamic.return

  describe("#makeStore", () => {
    describe("empty", () => {
      let result = FieldArray.makeStore(~context,[])
      test("returns Valid", () => {
        expect(result)->toEqual(Valid([], []))
      })
    })

    describe("some invalid", () => {
      let result = FieldArray.makeStore(~context,[Valid(Some(Store.Valid("33", 33)), 33), Invalid(None, #Part)])
      test("returns invalid", () => {
        expect(result->Store.toEnum)->toEqual(#Invalid)
      })
    })
  })

  describe("#validate", () => {
    describe("empty", () => {
      testDone("returns Ok", (success, _failure) => {
        FieldArray.validate(false, context, Dirty([]))
        ->Dynamic.finally(result => {
          expect(result)->toEqual(Valid([], []))
          success();
        })
      })
    })

    describe("non-empty", () => {
      describe("all valid", () => {
        let valid = [3, 4, 5]
        let input = valid->Js.Array2.map(x => Store.Dirty(Some(Store.Dirty(x->Belt.Int.toString))))
        testDone("returns Ok", (success, _failure) => {
          FieldArray.validate(false, context, Dirty(input))
          ->Dynamic.finally(result => {
            let output = result->FieldArray.output
            expect(output)->toEqual(Some(valid))
            success()
          })
        })
      })

      describe("some valid", () => {
        let indexBad = 1
        let bad = None
        let good = [Some(3), Some(5)]
        let input = good->Array.insert(bad, indexBad)->Js.Array2.map(x => x->Option.map(Belt.Int.toString)->FieldElement.set)->Store.Dirty

        let result = FieldArray.validate(false, context, input)
        let errorElement = FieldArray.Element.validate(false, context.element, Dirty(bad))
        let errors =
          result
          ->Dynamic.map(result =>
            switch result {
            | Invalid(_, errors) => errors
            | _ => Js.Exn.raiseError("asserted above")
            }
          )

        testDone("returns Error", (success, _failure) => {
          result->Dynamic.finally(result => {
            expect(result->Store.toEnum)->toEqual(#Invalid)
            success()
          })
        })

        testDone("returns field Error at index", (success, _failure) => {
          (errors, errorElement)
          ->Dynamic.combineLatest2
          ->Dynamic.finally(((errors, errorElement)) => {
            let error = errors->Js.Array2.unsafe_get(indexBad)
            expect(error)->toEqual(errorElement)
            success()
          })
        })

        testDone("returns Ok at other indices", (success, _failure) => {
          errors->Dynamic.finally(errors => {
            expect(
              errors
              ->Array.remove(indexBad)
              ->Js.Array2.every(x =>
                switch x {
                | Valid(_) => true
                | _ => false
                }
              ),
            )->toEqual(true)
            success()
          })
        })
      })
    })
  })

  describe("#reduce", () => {
    let input = [Some(3), None]
    let store = input->Js.Array2.map(Option.map(_, Belt.Int.toString))->FieldArray.set->Dynamic.return
    describe("#Set", () => {
      let new = [None, None, Some(666)]
      let change = #Set(new->Js.Array2.map(Option.map(_, Belt.Int.toString)))
      let result = FieldArray.reduce(~context, store, change)
      testDone("returns Invalid", (success, _fail) => {
        // Should actually check that type is promited
        result->Dynamic.finally(result => {
          expect(result->Store.toEnum)->toEqual(#Invalid)
          success()
        })
      })
      // test("returns new value", () => {
      //   expect(result)->toEqual(new)
      // })
    })

    describe("#Clear", () => {
      let change = #Clear
      let result = FieldArray.reduce(~context, store, change)
      testDone("returns empty", (success, _fail) => {
        result->Dynamic.finally(result => {
          expect(result)->toEqual(Valid([], []))
          success()
        })
      })
    })

    describe("#Add", () => {
      let new = Some(666)
      let change = #Add(#Some(new->Option.map(Belt.Int.toString)))
      let result = FieldArray.reduce(~context, store, change)
      let innerstore = result->Dynamic.map(Store.inner)

      testDone("increases length by 1", (success, _failure) => {
        innerstore->Dynamic.finally(innerstore =>{
          expect(innerstore->Js.Array2.length)->toEqual(input->Js.Array2.length + 1)
          success()
        })
      })

      testDone("appends new value ", (success, _failure) => {
        let last =
          innerstore->Dynamic.map(innerstore =>
            Js.Array2.unsafe_get(innerstore, innerstore->Js.Array2.length - 1)
          )
        last->Dynamic.finally(last => {
          expect(last)->toEqual(Dirty(new->Option.map(x => x->Belt.Int.toString->Store.dirty)))
          success()
        })
      })

      testDone("leaves prefix unmodified", (success, _failure) => {
        innerstore->Dynamic.finally(innerstore => {
          let prefix = innerstore->Js.Array2.slice(~start=0, ~end_=innerstore->Js.Array2.length - 1)
          expect(prefix)->toEqual(input->Js.Array2.map(x => x->Option.map(Belt.Int.toString)->FieldElement.set))
          success()
        })
      })
    })

    describe("#Index", () => {
      let new = 666
      let index = 1
      let change = #Index(index, #Some(#Set(new->Belt.Int.toString)))
      let result = FieldArray.reduce(~context, store, change)
      let innerstore = result->Dynamic.map(Store.inner)
      testDone("returns new value", (success, _failure) => {
        innerstore->Dynamic.finally(innerstore => {
          expect(innerstore->Js.Array2.unsafe_get(index))->toEqual(
            Valid(Some(Valid(new->Belt.Int.toString, new)), new),
          )
          success()
        }
        )
      })
    })

    describe("#Remove", () => {
      describe("out of bounds", () => {
        let index = 5
        let change = #Remove(index)
        let result = FieldArray.reduce(~context, store, change)
        testDone("returns input", (success, _failure) => {
          result->Dynamic.finally(result => {
            expect(result->FieldArray.input)->toEqual(input->Js.Array2.map(Option.map(_, Belt.Int.toString)))
            success()
          })
        })
      })

      describe("in bounds", () => {
        let index = 1
        let change = #Remove(index)
        let result = FieldArray.reduce(~context, store, change)
        testDone("decreases array length by 1", (success, _failure) => {
          result->Dynamic.finally(result => {
            let inner = result->Store.inner
            expect(inner->Js.Array2.length)->toEqual(input->Js.Array2.length - 1)
            success()
          })
        })
        // TODO check other elements
      })
    })
  })
})
