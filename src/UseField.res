@@ocamldoc("A Functor for creating a React hook for executing a Field")
module Make = (F: Field.T) => {
  type ret = Form.t<F.t, F.actions<()>>
  let use = (. ~context: F.context, ~init: option<Field.Init.t<F.input>>): ret => {
    let (first, dyn, _set, _validate) = React.useMemo0( () => {
      let set =
        init
        ->Option.map(Field.Init.get)
        ->Option.map(Rxjs.Subject.make)
        ->Option.or(Rxjs.Subject.makeEmpty())

      let validate = Rxjs.Subject.makeEmpty()

      let {first, init, dyn} = F.makeDyn(context, init, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)

      // FIXME: This concat->switch causes init to die right away since init and dyn are both there right away
      // Moving switchSequence into the array lets init finish, but then dyn splats a "Dirty" frame until the first event comes in??
      // But maybe only for Array?
      // Working around it by using skip
      let dyn =
        [ init
        , dyn->Dynamic.switchSequence
        ->Rxjs.pipe(Rxjs.skip(1))
        ]
        ->Rxjs.concatArray

      (first, dyn, set, validate)
    })


    let (close, setclose) = React.useState((_): Close.t<Form.t<F.t, F.actions<()>>> => first)

    let _ = React.useMemo0( () => {
      dyn
      ->Dynamic.tap(x => setclose(_ => x))
      ->Dynamic.toPromise
      ->Promise.void
    })

    close->Close.pack
  }
}
