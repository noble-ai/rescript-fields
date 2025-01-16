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
  module MkDyn = Test.MkDyn(Subject)

  describe("makeDyn", () => {
    describe("context default", () => {
      let context: Subject.context = {}

      describe("setOuter", () => {
        let test = (values) =>
          MkDyn.test(context,
            values->Array.map( v => #Set(v) )
          )()

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
        let test = MkDyn.test(context,
          [ #Set(Some("3"))
          , #Set(Some("5"))
          , #Set(None)
          ]
        )

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
          let test = MkDyn.test(context,
            [ #Action( ({opt})=> opt(Some("3")) )
            , #Action( ({opt})=> opt(None) )
            , #Action( ({opt})=> opt(Some("4")) )
            , #Action( ({opt})=> opt(None) )
            ]
          )

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
