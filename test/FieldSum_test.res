open Vitest
open FieldSum

module Gen = {
  @deriving(accessors)
  type structure<'a, 'b> = {
    left: 'a,
    right: 'b,
  }

  let order = (left, right)
  let fromTuple = ((left, right)) => {left, right}
}

type structure<'a, 'b> = Left('a) | Right('b)

module Subject = Sum2.Field(
  {
    type t<'a, 'b> = structure<'a, 'b>
    let toSum = (t: t<'a, 'b>) => {
      switch t {
      | Left(left) => #B(left)
      | Right(right) => #A(right)
      }
    }
    let fromSum = (s: Sum2.sum<'a, 'b>) => {
      switch s {
      | #B(left) => Left(left)
      | #A(right) => Right(right)
      }
    }
    let validateImmediate = true
  },
  Gen,
  FieldIdentity.String,
  FieldIdentity.String,
)

describe("FieldSum", () => {
  describe("Sum2", () => {
    describe("init", () =>{
      describe( "with empty context", () => {
        let context: Subject.context = {inner: {left: {}, right: {}}}
        describe("#default", () => {
          let subject = Subject.init(context)
          it("starts in init state", () => expect(subject->Subject.enum)->toEqual(#Init))
          it("gives no output", () => expect(subject->Subject.output)->toEqual(None))
          it("takes the A value, with empty string", () => expect(subject->Subject.input)->toEqual(Left("")))
        })
      })
    })
    describe( "#Set", () => {
        describe( "with empty context", () => {
            let context: Subject.context = {inner: {left: {}, right: {}}}
            describe( "from an initial state", () => {
                let subject = Subject.init(context)
                describe( "Sending Right", () => {
                    let value = "foo"
                    let change = #Set(Right(value))
                    let result =
                      subject
                      ->Dynamic.return
                      ->Subject.reduce(~context, {value: change, index: 0, priority: 0})
                      ->Dynamic.toPromise
                    itPromise("Becomes valid", () => result->Promise.tap( result => expect(result->Subject.enum)->toEqual(#Valid),))
                    itPromise("Has Right value as output", () => result->Promise.tap( result => expect(result->Subject.output)->toEqual(Some(Right(value)))))
                  })
              })
          })
      })
  })
})
