open Vitest
describe("FieldIdentity", () => {
  module Subject = FieldIdentity.Float
  let value = 3.0
  let input = Store.dirty(value)
  describe("#validate", () => {
    // Incredible. but an Identity field can only ever hold a value, so its always ok
    testPromise("should return Ok", () => {
      Subject.validate( false, ({}: Subject.context), input)
      ->Dynamic.toPromise
      ->Promise.tap(x => expect(x)->toEqual(Valid(value, value)))
    })
  })

  describe("#makeDyn", () => {
    describe("context empty", () => {
      let context: Subject.context = {}
      describe("#setOuter", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let validate = Rxjs.Subject.makeEmpty()
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}

          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

          [ (.) => set->Rxjs.next(3.0)
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        testPromise("returns the change value", () => {
          test()->Promise.tap(result => result->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })

      describe("#validateOuter", () => {
        let test = () => {

          let set = Rxjs.Subject.makeEmpty()
          let validate = Rxjs.Subject.makeEmpty()
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}

          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toHistory

          [ (.) => set->Rxjs.next(3.0)
          , (.) => validate->Rxjs.next()
          , (.) => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        testPromise("emits a new value for validate", () => {
          test()->Promise.tap(result => result->expect->toHaveLengthArray(2))
        })

        testPromise("returns the change value", () => {
          test()->Promise.tap(result => result->Array.leaf->Option.getUnsafe->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })

      describe("#set", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let validate = Rxjs.Subject.makeEmpty()
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}

          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

          [ (.)  => current.contents.pack.actions.set(3.0)
          , (.)  => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }
        testPromise("returns the change value", () => {
          test()->Promise.tap(result => result->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })

      describe("#clear", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let validate = Rxjs.Subject.makeEmpty()
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}

          let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

          [ (.)  => current.contents.pack.actions.set(3.0)
          , (.)  => current.contents.pack.actions.clear()
          , (.)  => current.contents.close()
          ]
          ->Test.chain(~delay=500)
          ->Promise.bind(_ => res)
        }

        testPromise("returns the empty value", () => {
          test()->Promise.tap(result => result->Close.pack->Form.field->expect->toEqual(Store.Valid(0., 0.)))
        })
      })

      describe("#opt", () => {
        [("None", None, 0.0), ("Some(4.0)", Some(4.0), 4.0)]
        ->Array.forEach( ((name, value, out)) => {
          describe(name, () => {
            let test = () => {

              let set = Rxjs.Subject.makeEmpty()
              let validate = Rxjs.Subject.makeEmpty()
              let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
              let current: ref<'a> = {contents: first}

              let res = dyn->Dynamic.switchSequence->Current.apply(current)->Dynamic.toPromise

              [ (.)  => current.contents.pack.actions.set(3.0)
              , (.)  => current.contents.pack.actions.opt(value)
              , (.)  => current.contents.close()
              ]
              ->Test.chain(~delay=500)
              ->Promise.bind(_ => res)
            }

            testPromise("returns the expected value", () => {
              test()->Promise.tap(result => result->Close.pack->Form.field->expect->toEqual(Store.Valid(out, out)))
            })
          })
        })
      })
    })
  })
})
