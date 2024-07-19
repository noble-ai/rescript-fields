open Vitest

let applyCurrent = (dyn, current) => Dynamic.tap(dyn, x => current.contents = x)

describe("FieldArray", () => {

  describe("element FieldOpt.Int", () => {
    module FieldElement = FieldOpt.Int
    module Subject = FieldArray.Make(
      FieldElement,
      {
        type t = FieldElement.t
        let filter = FieldArray.filterIdentity
        let empty = _ => []
      }
    )

    describe("context default", () => {
      let context: Subject.context = {
        element: {}
      }

      describe("makeDyn", () => {
        let test = () => {
          let set = Rxjs.Subject.makeEmpty()
          let val = Rxjs.Subject.makeEmpty()
          let {first, dyn} = Subject.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
          let current: ref<'a> = {contents: first}

          let actions = first.pack->Form.actions

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

      describe("#validate", () => {
        describe("empty", () => {
          testPromise("returns Ok", () => {
            Subject.validate(false, context, Dirty([]))
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
                Subject.validate(false, context, Dirty(input))
                ->Dynamic.toPromise
                ->Promise.tap(result => {
                  let output = result->Subject.output
                  expect(output)->toEqual(Some(valid))
                })
              })
            })

            describe("with external validation, failing", () => {
              describe("fails constantly", () => {
                let message =  "Fails"
                let validate = (_arr) => Result.Error(message)->Promise.return
                let context: Subject.context = {validate, element: {}}
                let validated = Subject.validate(false, context, Dirty(input))
                let history = validated->Dynamic.toHistory
                testPromise("returns atleast one state", () => {
                  history
                  ->Promise.tap(x => x->Array.length->expect->toBeGreaterThanInt(0))
                })
                testPromise("begins With Busy", () => {
                  history
                  ->Promise.tap(result => expect(result->Array.getUnsafe(0)->Subject.enum)->toEqual(#Busy))
                })
                testPromise("returns Error", () => {
                  history
                  ->Promise.map(r => r->Array.leaf->Option.getExn(~desc="") )
                  ->Promise.tap(result =>
                    expect(result->Subject.error)->toEqual(Some(#Whole(message)))
                  )
                })
              })

              describe("example considering array values", () => {
                let message = "Elements must Sum to 100"
                let validate = (arr) => arr->Array.reduce((a,b) => a+b, 0)->Some->Option.guard(x => x == 100)->Result.fromOption(message)->Result.const()->Promise.return
                let context: Subject.context = {validate, element: {}}
                testPromise("returns Error", () => {
                  Subject.validate(false, context, Dirty(input))
                  ->Dynamic.toPromise
                  ->Promise.tap(result => {
                    expect(result->Subject.error)->toEqual(Some(#Whole(message)))
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

            let result = Subject.validate(false, context, input)
            testPromise("returns partial Error", () => {
              result->Dynamic.toPromise
              ->Promise.tap(result => {
                expect(result->Subject.error)->toEqual(Some(#Part))
              })
            })
          })
        })
      })
    })
  })

  describe("element FieldParse.String", () => {
    module FieldElement = FieldParse.String.Field
    module Subject = FieldArray.Make(
      FieldElement,
      {
        type t = FieldElement.t
        let filter = FieldArray.filterIdentity
      }
    )

    describe("context validation", () => {
      let context = (): Subject.context => {
        let delay: ref<int> = {contents: 100}

        let validateArr = (_x: Array.t<FieldElement.output>) => {
          let d = delay.contents
          delay.contents = delay.contents - 10
          Promise.sleep(d)->Promise.map(_ => Ok())
        }  

        // Each validation is a bit quicker than the last so the responses come back out of order
        let validateString = (_x: FieldElement.output) => {
            let d = delay.contents
            delay.contents = delay.contents - 10
            Promise.sleep(d)->Promise.map(_ => Ok())
          }
        {validate: validateArr, element: {validate: validateString}}
      }

      describe("#makeDyn", () => {
        describe("set external", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, None)
            let current: ref<'ab> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            Rxjs.next(set, ["set"])
            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void
            res
          }

          itPromise("sets", () => {
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(["set"]))
          })
        })

        describe("set action", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, None)
            let current: ref<'ab> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            first.pack.actions.set(["set"])
            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void

            res
          }

          itPromise("sets", () => {
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(["set"]))
          })
        })

        describe("add", () => {
          let test = (values) => {
            let set = Rxjs.Subject.makeEmpty()
            let {first,dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, None)
            let current: ref<'ab> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            values->Array.forEach(first.pack.actions.add)

            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void
            res
          }

          itPromise("adds", () => {
            test([None, Some("add")])->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(["", "add"]))
          })
        })

        describe("remove", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, None)
            let current: ref<'ab> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            first.pack.actions.add(None)
            first.pack.actions.add(Some("add"))
            first.pack.actions.remove(0)

            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void
            res
          }

          itPromise("removes", () => {
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(["add"]))
          })
        })

        describe("opt", () => {
          let test = (opt) => {
            let set = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, None)
            let current: ref<'ab> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            first.pack.actions.set(["set", "set2"])
            first.pack.actions.opt(opt)

            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void
            res
          }

          describe("some", () => {
            itPromise("sets", () => {
              test(Some(["opt", "opt2"]))->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(["opt", "opt2"]))
            })
          })
          describe("none", () => {
            itPromise("clears", () => {
              test(None)->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual([]))
            })
          })
        })

        describe("index", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, None)
            let current: ref<'ab> = {contents: first}

            // This share prevents the observable from emitting everything twice?
            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            first.pack.actions.set(["set0", "set1", "set2"])
              
            Promise.sleep(500)
            ->Promise.tap(_ => current.contents.pack.actions.index(0)->Option.forEach(index => index.set("index") ))
            ->Promise.delay(~ms=500)
            ->Promise.tap(_ => current.contents.close())
            ->Promise.void

            res
          }

          itPromise("indexes", () => {
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual(["index", "set1", "set2"]))
          })
        })

        describe("clear", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, None)
            let current: ref<'ab> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toHistory

            first.pack.actions.set(["set", "set2"])
            first.pack.actions.clear()

            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void
            res
          }

          itPromise("clears", () => {
            test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual([]))
          })
        })

        describe("reset", () => {
          let test = () => {
            let set = Rxjs.Subject.makeEmpty()
            let {first, dyn} = Subject.makeDyn(context(), None, set->Rxjs.toObservable, None)
            let current: ref<'ab> = {contents: first}

            let res = dyn->Dynamic.switchSequence->applyCurrent(current)->Dynamic.toPromise

            first.pack.actions.set(["set", "set2"])
            first.pack.actions.reset()

            Promise.sleep(500)->Promise.tap(_ => current.contents.close())->Promise.void

            res
          }

          itPromise("resets", () => {
            test()->Promise.tap(res => res->Close.pack->Form.field->Subject.input->expect->toEqual([]))
          })
        })
      })
    })

  })
})
