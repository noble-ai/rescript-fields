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
        let set = Rxjs.Subject.makeEmpty()
        let validate = Rxjs.Subject.makeEmpty()
        let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}

        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

        set->Rxjs.next(3.0)
        current.contents.close()
        testPromise("returns the change value", () => {
          res->Promise.tap(result => result->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })

      describe("#validateOuter", () => {
        let set = Rxjs.Subject.makeEmpty()
        let validate = Rxjs.Subject.makeEmpty()
        let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}

        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toHistory

        set->Rxjs.next(3.0)
        validate->Rxjs.next()

        Promise.sleep(500)
        ->Promise.tap(_ => current.contents.close())
        ->Promise.void

        testPromise("emits a new value for validate", () => {
          res->Promise.tap(result => result->expect->toHaveLengthArray(2))
        })

        testPromise("returns the change value", () => {
          res->Promise.tap(result => result->Array.leaf->Option.getUnsafe->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })
 
      describe("#set", () => {
        let set = Rxjs.Subject.makeEmpty()
        let validate = Rxjs.Subject.makeEmpty()
        let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}

        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

        first.pack.actions.set(3.0)
        first.close()
        testPromise("returns the change value", () => {
          res->Promise.tap(result => result->Close.pack->Form.field->expect->toEqual(Store.Valid(value, value)))
        })
      })

      describe("#clear", () => {
        let set = Rxjs.Subject.makeEmpty()
        let validate = Rxjs.Subject.makeEmpty()
        let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
        let current: ref<'a> = {contents: first}

        let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

        first.pack.actions.set(3.0)
        first.pack.actions.clear()
        first.close()
        testPromise("returns the empty value", () => {
          res->Promise.tap(result => result->Close.pack->Form.field->expect->toEqual(Store.Valid(0., 0.)))
        })
      })

      describe("#opt", () => {
        [("None", None, 0.0), ("Some(4.0)", Some(4.0), 4.0)]
        ->Array.forEach( ((name, value, out)) => {
          describe(name, () => {
            let set = Rxjs.Subject.makeEmpty()
            let validate = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
            let current: ref<'a> = {contents: first}

            let res = dyn->Dynamic.switchSequence->FieldArray_test.applyCurrent(current)->Dynamic.toPromise

            current.contents.pack.actions.set(3.0)
            current.contents.pack.actions.opt(value)
            current.contents.close()

            testPromise("returns the expected value", () => {
              res->Promise.tap(result => result->Close.pack->Form.field->expect->toEqual(Store.Valid(out, out)))
            })
          })
        })
      })
    })
  })
})
