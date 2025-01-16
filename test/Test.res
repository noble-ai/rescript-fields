// This takes uncurried functions because an Array map yielding thunks has some
// bug where it dereferences undefined idk.
// let chain = (~delay, steps: array<(. unit) => ()>) => {
//   Promise.sequence( steps, x => Promise.return(x(.))
//   ->Promise.delay(~ms=delay))
//   ->Promise.const()
// }

module MkDyn = (F: Field.T) => {
  type step = [ #Action((F.actions<()>) => unit) | #Set(F.input) | #Validate ]

  let test = (~delay=200, context, steps: array<step>) => {
    () => {
      let set = Rxjs.Subject.makeEmpty()
      let val = Rxjs.Subject.makeEmpty()
      let {first, init, dyn} = F.makeDyn(context, None, set->Rxjs.toObservable, val->Rxjs.toObservable->Some)
      let current: ref<'a> = {contents: first}
      let res =
        Rxjs.concatArray([Dynamic.return(init), dyn])
        ->Dynamic.switchSequence
        ->Current.apply(current)
        ->Dynamic.toHistory

      Promise.sleep(delay)
      ->Promise.bind(_ => {
          Promise.sequence( steps, x => {
            switch x {
              | #Action(fn) => fn(current.contents.pack.actions)
              | #Set(v) => Rxjs.next(set, v)
              | #Validate => Rxjs.next(val, ())
            }
            ->Promise.return
            ->Promise.delay(~ms=delay)
          })
        ->Promise.tap(_ => current.contents.close())
        ->Promise.delay(~ms=delay)
        ->Promise.bind(_ => res)
      })
    }
  }
}