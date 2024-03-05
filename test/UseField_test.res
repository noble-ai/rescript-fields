open Vitest
open UseField
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
    module Subject = Make(FieldString)
    let context: Subject.context = {
      validate: (value: string) => {
        if value == "a" {
          Ok(value)
          ->Promise.return
          ->Promise.delay(~ms=0)
        } else {
          Ok(value)->Promise.return
        }
      },
    }

    let thunk = _ => Subject.use(~context, ~init="i", ~validateInit=false, ())
    let form = Tl.renderHook(thunk)

    beforeAllPromise(
      () => {
        Tl.actPromise(
          () => {
            form.result.current.reduce(#Set("a"))
            form.result.current.reduce(#Set("z"))
            form.result.current.reduce(#Set("q"))
            form.result.current.flush()->Promise.const()
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

  describe("with simple product", () => {
    describe(
      "applyChange",
      () => {
        module FieldString = FieldString.Make({
          let validateImmediate = false
        })

        module Subject = FieldProduct.Product2.Make(
          {
            let validateImmediate = false
          },
          Gen2,
          FieldString,
          FieldString,
        )

        let context: Subject.context = {
          inner: {
            left: {},
            right: {},
          },
        }

        describe(
          "Single change",
          () => {
            let left: FieldString.t = Valid("a", "a")
            let right: FieldString.t = Valid("b", "b")

            // let context: Rxjs.BehaviorSubject.t<Subject.context> = Rxjs.BehaviorSubject.make(context)
            let field: Subject.t = Dirty({left, right})
            let subject: Rxjs.t<Rxjs.behaviorsubject, Rxjs.source<'a>, 'a> = Rxjs.BehaviorSubject.make(field)
            let changeOut: Rxjs.Subject.t<(int, 'change)> = Rxjs.Subject.makeEmpty()
            let change = Subject.actions.left(#Set("q"))

            let res = applyChange(
              ~reduce=Subject.reduce(~context),
              ~subject,
              ~setfield=Void.void,
              ~changeOut,
              ~show=Subject.showChange,
              1,
              {change: change},
            )

            itPromise(
              "applies change to field",
              () => {
                res
                ->Rxjs.lastValueFrom
                ->Promise.map(
                  v => {
                    let {left} = v->Subject.input
                    expect(left)->toEqual("q")
                  },
                )
              },
            )
          },
        )
      },
    )
  })
})
