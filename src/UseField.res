@@ocamldoc("A Functor for creating a React hook for executing a Field")
module Make = (F: Field.T) => {
  type ret = Form.t<F.t, F.actions<()>>
  let use = (. ~context: F.context, ~init: option<F.input>, ~validateInit): ret => {
    let (first, dyn, set, validate) = React.useMemo0( () => {
      let set = 
        init
        ->Option.map(Rxjs.Subject.make)
        ->Option.or(Rxjs.Subject.makeEmpty())
        ->Rxjs.pipe(Rxjs.shareReplay(1))

      let validate = Rxjs.Subject.makeEmpty()

      let {first, dyn} = F.makeDyn(context, init, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
      let dyn = dyn->Dynamic.switchSequence

      (first, dyn, set, validate)
    })


    let (close, setclose) = React.useState((_): Close.t<Form.t<F.t, F.actions<()>>> => first)

    let _ = React.useMemo0( () => {
      dyn->Dynamic.tap(x => setclose(_ => x))
      ->Dynamic.toPromise
      ->Promise.void
    })
    
    React.useEffect0(() => {
      // Promise.sleep(30)
      // ->Promise.tap((_) => {
        init->Option.forEach(Rxjs.next(set))
      // })
      // ->Promise.void
      if validateInit {
        Rxjs.next(validate, ())
      }
      None
    })

    close->Close.pack
  }
}
