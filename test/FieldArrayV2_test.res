open Vitest

@deriving(accessors)
type structure<'a, 'b> = {
  username: 'b,
  password: 'a,
}

let applyCurrent = (dyn, current) => Dynamic.tap(dyn, x => current.contents = x)

describe("FieldArray", () => {

  describe("element FieldOpt.Int", () => {
    module FieldElement = FieldOpt.Int
    module Subject = FieldArray.Make(
      FieldElement,
      {
        type t = FieldElement.t
        let filter = FieldArray.filterIdentity
      }
    )

    describe("context default", () => {
      let context: Subject.context = {
        element: {}
      }

      describe("makeDyn", () => {
        let test = () => {
          // in UseField, if init is None, then set is Rxjs.Subject.makeEmpty()
          // in UseField, if init is Some, then set is Rxjs.Subject.make(init)
          let set = Rxjs.Subject.makeEmpty()
          // in UseField (L 12), validate is always Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          // in UseField (L 14), first is Close.t<Form.t<F.t, F.actions<unit>>>
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}
          // first.pack is Form.t<Subject.t, Subject.actions<unit>>, to unpack from Close.t
          let actions = first.pack->Form.actions

          // UseField (L15), call dyn->Dynamic.switchSequence
          let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

          let x: Subject.inputElement = Some("3")
          actions.add(None)
          actions.add(Some(x))
          actions.reset()
          set->Rxjs.next([Some("3"), Some("4"), Some("5")])

          Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void
          res
        }

        itPromise("set", () => {
          test()->Promise.tap(res => {
            // Console.log2("res", res)
            expect(res->Close.pack->Form.field->Subject.output)->toEqual(Some([3,4,5]))
          })
        })
      })
    })
  })

  describe("Element Product2", () => {
    module FieldPassword = FieldParse.String.Field
    module FieldUsername = FieldParse.String.Field
    // Declare the structure of your desired output type
    // This is outside of Generic to make accessors more easily available

    // Give fields a map from your output type to a generic container (tuple)
    module Generic = {
      type structure<'a, 'b> = structure<'a, 'b>

      let order = (password, username)
      let fromTuple = ((password, username)) => {username, password}
    }

    // Combine the Generic and child Fields to create a product field
    module FieldElement = FieldProduct.Product2.Make(
      Generic,
      FieldUsername,
      FieldPassword,
    )

    module Subject = FieldArray.Make(
      FieldElement,
      {
        type t = FieldElement.t
        let filter = FieldArray.filterIdentity
      }
    )

    describe("context default with init None", () => {
      let context: Subject.context = {
        element: { inner: { username: {}, password: {} } }
      }

      describe("#makeDyn", () => {
        describe("init None, then add None", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            // 1. here, init is None
            let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, None)
            let current: ref<'abc> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            // 2. then, add None
            first.pack.actions.add(None) // Is it equivalent to add(#Empty) that we have before this version?

            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void
            res
          }

          itPromise("adds None", () => {
            // Passed test
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual([{username: "", password: ""}]))
          })
        })

        describe("init None, then add Some element input", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            // 1. here, init is None
            let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, None)
            let current: ref<'abc> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            // 2. then, add some element username input
            let elementInput: option<FieldElement.input> = {username: "username", password: ""}->Some
            first.pack.actions.add(elementInput)

            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void
            res
          }

          itPromise("adds Some", () => {
            // Passed test
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual([{username: "username", password: ""}]))
          })
        })

        describe("init None, add None then set inner", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            // 1. here, init is None
            let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, None)
            let current: ref<'abc> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            // 2. then, add None (mimick user click add button)
            first.pack.actions.add(None)

            Promise.sleep(500)
            // ->Promise.tap(_ => {
            //   let _temp = current.contents.pack.field->Subject.input
            //   Js.log2("BEFORE set username", _temp)
            // })
            ->Promise.tap(_ => current.contents.pack.actions.index(0)->Option.forEach(index => {
              // 3. then, set inner username (mimick user fill out the username input)
              index.inner.username.set("username")
              // index.inner.password.set("password")
            }))
            // ->Promise.tap(_ => {
            //   let _temp = current.contents.pack.field->Subject.input
            //   Js.log2("AFTER set username", _temp)
            // })
            ->Promise.delay(~ms=500)
            ->Promise.tap(_ => current.contents.close())
            ->Promise.void

            res
          }

          itPromise("adds first username", () => {
            // Failed test
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual([{username: "username", password: ""}]))
          })
        })

        describe("init None, add Some then set inner", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            // 1. here, init is None
            let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, None)
            let current: ref<'abc> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            // 2. then, add some element username input (mimick user click add button)
            let elementInput: option<FieldElement.input> = {username: "", password: ""}->Some
            first.pack.actions.add(elementInput)

            Promise.sleep(500)
            // ->Promise.tap(_ => {
            //   let _temp = current.contents.pack.field->Subject.input
            //   Js.log2("BEFORE set username", _temp)
            // })
            ->Promise.tap(_ => current.contents.pack.actions.index(0)->Option.forEach(index => {
              // 3. then, set inner username (mimick user fill out the username input)
              index.inner.username.set("username")
              // index.inner.password.set("password")
            }))
            // ->Promise.tap(_ => {
            //   let _temp = current.contents.pack.field->Subject.input
            //   Js.log2("AFTER set username", _temp)
            // })
            ->Promise.delay(~ms=500)
            ->Promise.tap(_ => current.contents.close())
            ->Promise.void

            res
          }

          itPromise("adds first username", () => {
            // Failed test
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual([{username: "username", password: ""}]))
          })
        })


      })
    })
  })

})
