open Vitest
module Tl = TestingLibrary

module Gen2 = {
  @deriving(accessors)
  type structure<'a, 'b> = {
    left: 'a,
    right: 'b,
  }
  let order = (left, right)
  let fromTuple = ((left, right)) => {left, right}
}

describe("UseField", () => {
  describe("out of order validation", () => {
    module FieldString = FieldString.Make({
      let validateImmediate = true
    })
    module Subject = UseField.Make(FieldString)
    let context: FieldString.context = {
      validate: (value: string) => {
        if value == "a" {
          Ok()
          ->Promise.return
          ->Promise.delay(~ms=0)
        } else {
          Ok()->Promise.return
        }
      },
    }

    let thunk = _ => Subject.use(. ~context, ~init=Some("i"), ~validateInit=false)
    let form = Tl.renderHook(thunk)

    beforeAll(
      () => {
        Tl.act(
          () => {
            form.result.current.actions.set("a")
            form.result.current.actions.set("z")
            form.result.current.actions.set("q")
            // form.result.current.flush()->Promise.const()
          },
        )
      },
    )

    it(
      "keeps the third value",
      () => {
        expect(form.result.current.field->FieldString.input)->toEqual("q")
      },
    )
  })

  // describe("with simple product", () => {
    // describe(
    //   "applyChange",
    //   () => {
    //     module FieldString = FieldString.Make({
    //       let validateImmediate = false
    //     })

    //     module Subject = FieldProduct.Product2.Make(
    //       {
    //         let validateImmediate = false
    //       },
    //       Gen2,
    //       FieldString,
    //       FieldString,
    //     )

    //     let context: Subject.context = {
    //       inner: {
    //         left: {},
    //         right: {},
    //       },
    //     }

    //     describe(
    //       "Single change",
    //       () => {
    //         let left: FieldString.t = Valid("a", "a")
    //         let right: FieldString.t = Valid("b", "b")

    //         // let context: Rxjs.BehaviorSubject.t<Subject.context> = Rxjs.BehaviorSubject.make(context)
    //         let field: Subject.t = Dirty({left, right})
    //         let subject = Rxjs.Subject.makeBehavior(field)
    //         let changeOut: Rxjs.t<'c, 's, (int, 'change)> = Rxjs.Subject.makeEmpty()
    //         let change = Subject.actions.inner.left.set("q")

    //         let res = UseField.applyChange(
    //           ~reduce=Subject.reduce(~context),
    //           ~subject,
    //           ~setfield=Void.void,
    //           ~changeOut,
    //           ~show=Subject.showChange,
    //           1,
    //           {change: change},
    //         )

    //         itPromise(
    //           "applies change to field",
    //           () => {
    //             res
    //             ->Rxjs.lastValueFrom
    //             ->Promise.map(
    //               v => {
    //                 let {left} = v->Subject.input
    //                 expect(left)->toEqual("q")
    //               },
    //             )
    //           },
    //         )
    //       },
    //     )
    //   },
    // )
  // })
})
