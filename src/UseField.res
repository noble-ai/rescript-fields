module Make = (F: Field.T) => {
  type ret = Form.t<F.t, F.actions<()>>
  let use = (. ~context: F.context, ~init: option<F.input>, ~validateInit): ret => {
    let (first, dyn) = React.useMemo0( () => {
      let set = init->Option.map(Rxjs.Subject.make)->Option.or(Rxjs.Subject.makeEmpty())
      let validate = Rxjs.Subject.makeEmpty()

      let {first, dyn} = F.makeDyn(context, set->Rxjs.toObservable, validate->Rxjs.toObservable->Some)
      let dyn = dyn->Dynamic.switchSequence

      (first, dyn)
    })

    // FIXME: apply init value
    let (close, setclose) = React.useState((_): Close.t<Form.t<F.t, F.actions<()>>> => first)

    React.useEffect0(() => {
      let sub = Rxjs.subscribe(dyn, {
        next: (. x) => setclose(_ => x),
        complete: (.) => (),
        error: (. _) => ()
      })
      Some(() => sub->Rxjs.unsubscribe)
    })

    close->Close.pack
  }
}
