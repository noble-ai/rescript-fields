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
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some) 
          let current: ref<'a> = {contents: first}

          let hist = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

          values->Array.forEach(Rxjs.next(set))

          Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void

          hist
        }

        describe("some", () => {
          let values = [ Some("3")]
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
      let context: Subject.context = { validate: (_x) => Ok()->Promise.return->Promise.delay(~ms=100) } 
      describe("Clear during validate", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some) 
          let current: ref<'a> = {contents: first}

          let hist = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

          Rxjs.next(set, Some("3"))
          Rxjs.next(set, Some("5"))
          Rxjs.next(set, None)

          Promise.sleep(2000)->Promise.tap(_ => current.contents.close())->Promise.void

          hist
        }

        itPromise("shows busy", () => {
          test()->Promise.tap( hist => {
            hist->Array.map(x => x.pack.field->Subject.enum)->expect->toContainEqual(#Busy)
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
            let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some) 
            let current: ref<'a> = {contents: first}

            let hist = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

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
