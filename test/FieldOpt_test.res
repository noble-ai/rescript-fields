open Vitest

module Behaviors = (F: Field.T) => {
  let capturesInputs = (hist, expected) => {
    let inputs = hist
      ->Array.map( state => 
        state
        ->Close.pack
        ->Form.field
        ->F.input
      )

    expected
    ->Array.forEach( input => { 
      inputs
      ->expect
      ->toContainArray(input)
    })
  }
}


// shadow global Dynamic with the impl chosen by FT
describe("FieldOpt", () => {
  module Subject = FieldOpt.Int
  module Behaviors = Behaviors(Subject) 

  describe("makeDyn", () => {
    describe("context default", () => {
      let context: Subject.context = {}

      describe("setOuter", () => {
        let test = (values) => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some) 
          let current: ref<'a> = {contents: first}

          let hist = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

          values->Array.forEach(Rxjs.next(set))

          Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void

          hist
        }

        describe("some", () => {
          let values = [ Some("3")]
          itPromise("returns one value per value", () => {
            test(values)->Promise.tap( hist => {
              hist->expect->toHaveLengthArray(values->Array.length)
            })
          })

          itPromise("applies value", () => {
            test(values)->Promise.tap( res => 
              res
              ->Array.leaf
              ->Option.getUnsafe
              ->Close.pack
              ->Form.field
              ->expect
              ->toEqual(Store.Valid(Some(Valid("3", 3)), 3))
            )
          })
        })

        describe("None", () => {
          let values = [ Some("3"), Some("4"), None ]
          itPromise("returns one value per value", () => {
            test(values)->Promise.tap( hist => {
              hist->expect->toHaveLengthArray(values->Array.length)
            })
          })

          itPromise("clears value", () => {
            test(values)
            ->Promise.tap( res => 
              res
              ->Array.leaf
              ->Option.getUnsafe
              ->Close.pack
              ->Form.field
              ->expect
              ->toEqual(Store.Init(None))
            )
          })
        })
      })
    })

    describe("context valdiate", () => {
      let context: Subject.context = { validate: (x) => Ok(x)->Promise.return->Promise.delay(~ms=100) } 
      describe("Clear during validate", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some) 
          let current: ref<'a> = {contents: first}

          let hist = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

          Rxjs.next(set, Some("3"))
          Rxjs.next(set, Some("5"))
          Rxjs.next(set, None)

          Promise.sleep(2000)->Promise.tap(_ => current.contents.close())->Promise.void

          hist
        }

        itPromise("begins busy", () => {
          test()->Promise.tap( hist => {
            hist
            ->Array.head
            ->Option.getUnsafe
            ->Close.pack
            ->Form.field
            ->Subject.enum
            ->expect
            ->toEqual(#Busy)
          })
        })

        itPromise("captures every input", () => {
          test()->Promise.tap( hist => {
            hist->Behaviors.capturesInputs([Some("3"), Some("5")])
          })
        })

        itPromise("ends with clear", () => {
          test()->Promise.tap( res => 
            res
            ->Array.leaf
            ->Option.getUnsafe
            ->Close.pack
            ->Form.field
            ->expect
            ->toEqual(Store.Init(None))
          )
        })
      })

      describe("actions", () => {
        describe("opt", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            let val = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context, set->Rxjs.toObservable, val->Rxjs.toObservable->Some) 
            let current: ref<'a> = {contents: first}

            let hist = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

            current.contents.pack.actions.opt(Some("3"))
            current.contents.pack.actions.opt(None)
            current.contents.pack.actions.opt(Some("4"))

            Promise.sleep(500)->Promise.tap(_ => current.contents.pack.actions.opt(None))->Promise.void

            Promise.sleep(800)->Promise.tap(_ => current.contents.close())->Promise.void

            hist
          }

          itPromise("captures every input", () => {
            test()->Promise.tap( hist => {
              hist->Behaviors.capturesInputs([Some("3"), Some("4")])
            })
          })

          itPromise("ends with clear", () => {
            test()->Promise.tap( res => 
              res
              ->Array.leaf
              ->Option.getUnsafe
              ->Close.pack
              ->Form.field
              ->expect
              ->toEqual(Store.Init(None))
            )
          })
        })
      })
    })
  })
})
