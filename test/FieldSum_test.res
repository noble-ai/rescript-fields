open Vitest

module FieldString = FieldParse.String.Field

module Gen = {
  @deriving(accessors)
  type structure<'a, 'b> = {
    haha: 'a,
    nono: 'b,
  }

  let order = (haha, nono)
  let fromTuple = ((haha, nono)) => {haha, nono}
}

type structure<'a, 'b> = Haha('a) | Nono('b)

module Subject = FieldSum.Sum2.Make(
  {
    type t<'a, 'b> = structure<'a, 'b>
    let toSum = (t: t<'a, 'b>) => {
      switch t {
      | Haha(left) => #B(left)
      | Nono(right) => #A(right)
      }
    }
    let fromSum = (s: FieldSum.Sum2.sum<'a, 'b>) => {
      switch s {
      | #B(left) => Haha(left)
      | #A(right) => Nono(right)
      }
    }
  },
  Gen,
  FieldString,
  FieldString,
)

module MkDyn = Test.MkDyn(Subject)

describe("FieldSum", () => {
  describe("Sum2", () => {
    describe( "context empty", () => {
      let context: Subject.context = {inner: {haha: {}, nono: {}}}
      describe("#default", () => {
        let subject = Subject.init(context)
        it("starts in init state", () => expect(subject->Subject.enum)->toEqual(#Init))
        it("gives no output", () => expect(subject->Subject.output)->toEqual(None))
        it("takes the A value, with empty string", () => expect(subject->Subject.input)->toEqual(Haha("")))
      })

      describe("#makeDyn", () => {
        describe("setOuter", () => {
          let values = [Haha("one"), Nono("2"), Haha("three")]

          let test = MkDyn.test(context,
            values->Array.map( v => #Set(v) )
          )

          itPromise("applys last value", () => {
            test()->Promise.tap(res => res->Array.leaf->Option.getUnsafe->Close.pack->Form.field->Subject.input->expect->toEqual(values->Array.leaf->Option.getUnsafe))
          })
        })
      })
    })
  })
})
