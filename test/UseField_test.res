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
    module Subject = UseField.Make(FieldParse.String.Field)
    let context: FieldParse.String.Field.context = {
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

    let thunk = _ => Subject.use(. ~context, ~init=Some(Natural("i")))
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
        expect(form.result.current.field->FieldParse.String.Field.input)->toEqual("q")
      },
    )
  })
})
