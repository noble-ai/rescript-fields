type key = int
let key: ref<key> = {contents: 0}
let getKey = () => {
  let k = key.contents
  key.contents = key.contents + 1
  k
}

module Context = {
  type structure<'output, 'element, 'empty> = {
    @ocamldoc("External validation for array recieves output from all valid children
    FieldArray does have this concept of filtering in IArray to consider, maybe we want to pass that last one in?
    / or just pass the Store and let it filter? -AxM
    ")
    validate?: array<'output> => Promise.t<Result.t<unit, string>>,
    element: 'element,
    empty?: () => array<'empty>,
    validateImmediate?: bool,
  }
}

let length = (~len, arr) => {
  if arr->Array.length < len {
    Error("Must have at least " ++ string_of_int(len) ++ " elements")
  } else {
    Ok()
  }->Promise.return
}

let traverseTuple3 = (arr: array<'a>, fn: 'a => ('b, 'c, 'd)): (array<'b>, array<'c>, array<'d>) => {
  let a = []
  let b = []
  let c = []
  arr->Array.forEach(x => {
    let (x, y, z) = fn(x)
    a->Array.Mut.push(x)->ignore
    b->Array.Mut.push(y)->ignore
    c->Array.Mut.push(z)->ignore
  })

  (a, b, c)
}

let traverseTupleSnd = ((a, b): ('a, 'b), fn: 'b => Rxjs.Observable.t<'c>): Rxjs.Observable.t<('a, 'c)> => {
  fn(b)
  ->Dynamic.map(b => (a, b))
}

let mergeCloses = (closes) => {
  () => {
    closes->Array.forEach(x => x())
  }
}

let mergeInner =  (array: array<Close.t<Form.t<'fa, 'aa>>>): Close.t<Form.t<'f, 'a>> => {
  let field = array->Array.map(x => x.pack.field)
  let actions = array->Array.map(x => x.pack.actions)
  let close = mergeCloses(array->Array.map(Close.close))
  { pack: { field, actions }, close }
}

// Observables are not guaranteed to emit.
// and if we apply a startWith on each element
// We will cause an emission before any signal was recieved.
// So instead we use a default value array
// and multiplex all the changes by index
// and then applyLatest combines them, taking the init as value
// for any indices that have not yet emitted
let combineLatestScan = {
  // With an existing array, and an index/value pair, apply the
  let applyLatest = (d: Array.t<'a>, (hs, index): ('a, int), _index: int): Array.t<'a> => Array.setUnsafe(d, index, hs)

  (a: array<Rxjs.Observable.t<'a>>, init: array<'a>): Rxjs.Observable.t<array<'a>> => {
    a
    ->Array.mapi( (obs, i) => Dynamic.map(obs, x => (x, i) ))
    ->Rxjs.mergeArray
    ->Rxjs.pipe(Rxjs.scan(applyLatest, init))
  }
}

module type IArray =
{
  type t
  let filter: array<(key, t)> => array<(key, t)>
}

let filterIdentity = (a: array<'a>) => a

let filterGrace = (a: array<'t>) => {
  a->Array.slice(0, a->Array.length - 1)
}

type actions<'finput, 'factions, 'out> = {
  set: array<'finput> => 'out,
  add: option<'finput> => 'out,
  remove: int => 'out,
  opt: option<array<'finput>> => 'out,
  clear: () => 'out,
  reset: () => 'out,
  index: (int) => option<'factions>,
}


  module type T = {
    include Field.T
    type inputElement
    type parted
    let split: Form.t<t, actions<()>> => parted
  }

  type error = [#Whole(string) | #Part]

  module type Make = (F: Field.T, I: IArray with type t = F.t ) => T
    with type input = array<F.input>
    and type inputElement = F.input
    // Array maintains keys for elements here, to help React know when to unmount
    and type inner = array<(key, F.t)>
    and type output = array<F.output>
    and type error = error
    and type t = Store.t<array<(key, F.t)>, array<F.output>, error>
    and type context = Context.structure<F.output, F.context, F.input>
    and type actions<'change> = actions<F.input, F.actions<'change>, 'change>
    and type parted = array<(key, Form.t<F.t, F.actions<()>>)>

module Make: Make = (F: Field.T, I: IArray with type t = F.t) => {
  module Element = F
  type context = Context.structure<Element.output, Element.context, Element.input>

  type inputElement = Element.input
  type input = array<Element.input>
  let showInput = (input: input) => {
    `[ ${input->Array.map(Element.showInput)->Array.joinWith(",\n")} ]`
  }

  type output = array<Element.output>
  type error = error
  type inner = array<(key, Element.t)>
  type t = Store.t<inner, output, error>

  let setKeyed = Array.mapi(_, (x, i) => (i, F.set(x)))
  // FIXME: use a key hash or something. these will overlap on previous pretty easily
  let empty: context => inner = (context) => Option.flap0(context.empty)->Option.or([])->setKeyed
  let init: context => t = context => context->empty->Store.init

  let set = (input: input): t => input->setKeyed->Dirty

  let makeOutput = (inner: inner): Result.t<array<F.output>, 'err> =>
    inner->Array.reduce((res, (_key, element)) => {
      switch element->F.output {
      | Some(output) => res->Result.bind(res => Ok(Array.concat(res, [output])))
      | None => Error(element->F.enum)
      }
    }, Ok([]))

  let toKey = Tuple.fst2
  let toElement = Tuple.snd2
  let toEnums = Array.map(_, x => x->toElement->Element.enum)

  let prefer = (enum, make, inner): Result.t<'a, 'e> =>
    // First Prioritize Busy first if any children are busy
    Result.predicate(
      inner->toEnums->Array.some(x => x == enum),
      make(inner)->Dynamic.return,
      #Invalid,
    )

  let preferFiltered = (enum, make, inner, filtered): Result.t<'a, 'e> =>
    // First Prioritize Busy first if any children are busy
    Result.predicate(
      filtered->toEnums->Array.some(x => x == enum),
      make(inner)->Dynamic.return,
      #Invalid,
    )

  let validateImpl = (context: context, force, inner): Result.t<Rxjs.Observable.t<'out>, 'err> => {
    Result.first(makeOutput(inner), makeOutput(inner->I.filter))
    ->Result.mapError(_ => #Invalid)
    ->Result.map(out => {
      switch context.validate {
      | Some(validate) if context.validateImmediate->Option.or(true) || force =>
        validate(out)
        ->Dynamic.fromPromise
        ->Dynamic.map(
          Result.resolve(
            ~ok=_ => Store.valid(inner, out),
            ~err=e => Store.invalid(inner, #Whole(e)),
          ),
        )
        ->Dynamic.startWith(Store.busy(inner))
      // When we are given a validate function but not validateImmediate or force, do not assume valid until validated
      | Some(_validate) => Store.dirty(inner)->Dynamic.return
      | _ => Store.valid(inner, out)->Dynamic.return
      }
    })
  }

  // Just like FieldProduct makeStore, but for an array of same elements
  let makeStore = (~validate, inner: inner): Rxjs.Observable.t<t> => {
    [
      prefer(#Busy, Store.busy, inner),
      preferFiltered(#Invalid, Store.invalid(_, #Part), inner, inner->I.filter),
      preferFiltered(#Dirty, Store.dirty, inner, inner->I.filter),
      validate(inner),
    ]
    ->Array.reduce(Result.first, Error(#Invalid))
    ->Result.resolve(~ok=x => x, ~err=x => FieldVector.resolveErr(inner, x)->Dynamic.return)
  }

  let validate = (force, context: context, store: t): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
    // Using combineLatest to get the status of all children
    // requires there be children. so add shortcut for empty array
    let validate = validateImpl(context, force)
    let inner = store->Store.inner
    if inner == [] {
      makeStore(~validate, inner)
    } else {
      inner
      ->Array.map(traverseTupleSnd(_, Element.validate(force, context.element)))
      ->Dynamic.combineLatest
      ->Dynamic.bind(makeStore(~validate))
    }
  }

  type actions<'change> = actions<F.input, F.actions<'change>, 'change>
  let mapActions: (actions<'ch>, 'ch => 'b) => actions<'b> = (actions, fn) => {
    set: input => input->actions.set->fn,
    clear: () => actions.clear()->fn,
    opt: input => input->actions.opt->fn,
    index: (i) => actions.index(i)->Option.map(F.mapActions(_, fn)),
    add: input => input->actions.add->fn,
    remove: i => i->actions.remove->fn,
    reset: () => actions.reset()->fn
  }

  type parted = array<(key, Form.t<F.t, F.actions<()>>)>
  let split = (pack: Form.t<t, actions<()>>): parted => {
    pack.field
    ->Store.inner
    ->Array.mapi( ((key, field), i): (key, Form.t<F.t, F.actions<()>>) => (key, {
      field,
      actions: pack.actions.index(i)->Option.getExn(~desc="fieldArray split"),
    }))
  }

  let enum = Store.toEnum

  let inner = Store.inner

  let input = (store: t) => {
    store->Store.inner->Array.map(x => x->toElement->Element.input)
  }

  let error = Store.error

  let output = Store.output

  let printErrorInner = (inner: inner) => {
    inner
    ->Array.map(x => x->toElement->F.printError)
    ->Array.map(Option.or(_, "None"))
    ->Array.mapi((a, i) => `${i->Int.toString}: ${a}`)
    ->Array.joinWith(", \n")
  }

  let printError = (store: t) => {
    store
    ->Store.error
    ->Option.map(error => {
      switch error {
        | #Whole(_error) => _error
        | #Part => store->Store.inner->printErrorInner
      }
    })
  }


  external outputToString: output => string = "%identity"
  let show = (store: t) => {
    `FieldArray{
      state: ${store->enum->Store.enumToPretty},
      input: ${store->input->showInput},
      output: ${store->Store.output->Option.map(outputToString)->Option.or("None")},
      children: [
        ${store->Store.inner->Array.map(x => x->toElement->Element.show)->Array.joinWith(",\n")}
      ]
    }`
  }

  let traverseSetk = (context: context, set, elements) => {
    elements
    ->Array.mapi( (value, index) => (value, index))
    ->traverseTuple3( ((value, index)) => {
      let key = getKey()
      let setElement = set->Dynamic.keepMap(Array.get(_, index))
      let {first, init, dyn} = F.makeDyn(context.element, Some(value), setElement, None)
      ((key, first), (key, init), (key, dyn))
    })
  }

  let packKeyValue = (key: key, p: Close.t<Form.t<F.t, F.actions<unit>>>):  Close.t<Form.t<(key, F.t), F.actions<unit>>> => {
    close: p.close
    , pack: {
      actions: p.pack.actions
      , field: (key, p.pack.field)
    }
  }


  let packKeyObss: (key, Dyn.init<Close.t<Form.t<F.t, F.actions<unit>>>>) => Dyn.init<Close.t<Form.t<(key, F.t), F.actions<unit>>>> = (key, v) => Dynamic.map(v, packKeyValue(key))
  let packKeyDyns: (key, Dyn.dyn<Close.t<Form.t<F.t, F.actions<()>>>>) => Dyn.dyn<Close.t<Form.t<(key, F.t), F.actions<()>>>> = (key, dyns) => Dynamic.map(dyns, Dynamic.map(_, packKeyValue(key)))

  let packKey:
    ( ( Array.t<(key, Close.t<Form.t<F.t, F.actions<unit>>>)>
      , Array.t<(key, Dyn.init<Close.t<Form.t<F.t, F.actions<unit>>>>)>
      , Array.t<(key, Dyn.dyn<Close.t<Form.t<F.t, F.actions<()>>>>)>
      )
    )
   => (
      Array.t<Close.t<Form.t<(key, F.t), F.actions<unit>>>>,
      Array.t<Dyn.init<Close.t<Form.t<(key, F.t), F.actions<unit>>>>>,
      Array.t<Dyn.dyn<Close.t<Form.t<(key, F.t), F.actions<()>>>>>
    ) =
      Tuple.napply3(
        ( Array.map(_, Tuple.uncurry2(packKeyValue))
        , Array.map(_, Tuple.uncurry2(packKeyObss))
        , Array.map(_, Tuple.uncurry2(packKeyDyns))
        )
      )

  let makeDynInner = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>)
    : (
      Array.t<Close.t<Form.t<(key, F.t), F.actions<unit>>>>,
      Array.t<Dyn.init<Close.t<Form.t<(key, F.t), F.actions<unit>>>>>,
      Array.t<Dyn.dyn<Close.t<Form.t<(key, F.t), F.actions<()>>>>>,
    )
   => {
      Option.first(initial, Option.flap0(context.empty))
      ->Option.or([])
      ->traverseSetk(context, set, _)
      ->packKey
    }

  let makeDyn = (context: context, initial: option<input>, setOuter: Rxjs.Observable.t<input>, _validate: option<Rxjs.Observable.t<()>>)
    : Dyn.t<Close.t<Form.t<t, actions<()>>>>
  => {
    // Every observable has a complete, to terminate the stream
    let complete = Rxjs.Subject.makeEmpty()

    // The observable inputs for an array
    let reset = Rxjs.Subject.makeEmpty()
    let setInner: Rxjs.t<'c, Rxjs.source<input>, input> = Rxjs.Subject.makeEmpty()
    let clearInner = Rxjs.Subject.makeEmpty()

    // Opt allows the value to be either set or clearned
    let opt: Rxjs.t<'c, Rxjs.source<option<input>>, option<input>> = Rxjs.Subject.makeEmpty()
    let setOpt = opt->Rxjs.pipe(Rxjs.keepMap(x => x))
    let clearOpt = opt->Rxjs.pipe(Rxjs.keepMap(Option.invert(_, ())))

    let add: Rxjs.t<'ca, Rxjs.source<option<F.input>>, option<F.input>> = Rxjs.Subject.makeEmpty()
    let remove: Rxjs.t<'cr, Rxjs.source<int>, int> = Rxjs.Subject.makeEmpty()

    // Close over all the array level observables except actionsInner
    // to produce an actions object constructor for this array
    let makeActions = (actionsInner):  actions<()> => {
      set: Rxjs.next(setInner),
      clear: Rxjs.next(clearInner),
      opt: Rxjs.next(opt),
      index: Array.get(actionsInner),
      add: Rxjs.next(add),
      remove: Rxjs.next(remove),
      reset: Rxjs.next(reset),
    }

    // Close this array completely. Maybe overkill
    let makeClose = (close: () => ()) => () => {
      close()
      // static observables
      Rxjs.complete(clearInner)
      Rxjs.complete(reset)
      Rxjs.complete(add)
      Rxjs.complete(remove)
      Rxjs.complete(opt)
      Rxjs.complete(setInner)
      Rxjs.next(complete, ())
    }

    let applyField = ({pack, close}: Close.t<Form.t<array<(key, 'aaf)>, 'baf>>) =>
          (field: t): Close.t<Form.t<t, actions<()>>> =>
            { pack:
              { field: field
              , actions: makeActions(pack.actions)
              }
            , close: makeClose(close)
            }

    let applyInner = (inners): Rxjs.Observable.t<Close.t<Form.t<t, actions<()>>>> => {
        let inners = mergeInner(inners)
        inners.pack.field
        ->makeStore(~validate=validateImpl(context, false))
        ->Dynamic.map(applyField(inners))
      }

    let (firstInner, initInner, dynInner) = makeDynInner(context, initial, setOuter)

    // This is like applyInner but does not include makeStore which produces an observable.
    // We want one definite value, and now.
    let first: Close.t<Form.t<t, 'af>> = {
      let inners = mergeInner(firstInner)
      inners.pack.field
      ->Store.init
      ->applyField(inners, _)
    }

    let valuesToInputs = Array.map(_, (x: Close.t<Form.t<(key, F.t), 'aa>>) => x.pack.field->Tuple.snd2->Element.input)

    let stateValues =
      Rxjs.Subject.makeBehavior(firstInner)
      ->Rxjs.pipe(Rxjs.distinct())

    let stateObs =
      Rxjs.Subject.makeBehavior(initInner)
      ->Rxjs.pipe(Rxjs.distinct())

    let init = {
      combineLatestScan(initInner, firstInner)
      ->Dynamic.tap(Rxjs.next(stateValues))
      ->Dynamic.switchMap(applyInner)
    }

    let set = Rxjs.merge3(setOuter, setInner, setOpt)
    let clear = Rxjs.merge2(clearInner, clearOpt)


    let dynInner =
    // multiplex all the various Array level change signals
    // So we can scan on them, producing new arrays of F.t dyns.
      Rxjs.merge5(
        add->Dynamic.map(x => #Add(x)),
        remove->Dynamic.map(i => #Remove(i)),
        set->Dynamic.map(x => #Set(x)),
        clear->Dynamic.const(#Clear),
        reset->Dynamic.const(#Reset),
      )
      ->Dynamic.withLatestFrom2(stateValues, stateObs)
      ->Rxjs.pipe(Rxjs.scan(
        // The persistent values and obs are ignored in this scan,
        // Since they will have changed with element changes,
        // which are applied outside of the scan
        // stateValues and stateObs can be passed to the combineLatestArray step
        // So we take those instead
        ( ( _values, _obs, dyns, _)
        , ( change: 'change
          , stateValues: Array.t<Close.t<Form.t<(key, F.t), F.actions<unit>>>>
          , stateObs: Array.t<Rxjs.Observable.t<Close.t<Form.t<(key, F.t), F.actions<unit>>>>>
          )
        , _sequence)
      : ( Array.t<Close.t<Form.t<(key, F.t), F.actions<unit>>>>
        , Array.t<Dyn.init<Close.t<Form.t<(key, F.t), F.actions<unit>>>>>
        , Array.t
            < Either.t
              < (Dyn.init<Close.t<Form.t<(key, F.t), F.actions<unit>>>>, Dyn.dyn<Close.t<Form.t<(key, F.t), F.actions<()>>>>)
              , Dyn.dyn<Close.t<Form.t<(key, F.t), F.actions<()>>>>
              >
            >
        , Option.t<Array.t<Close.t<Form.t<(key, F.t), F.actions<unit>>>>>
        )
     => {
      // We are tracking the init of dynamically added elements in the 'dyn' value.
      // When a new array level change comes in, we no longer want to replay the init,
      // So cast all the eithers to right.
      let dyns = dyns->Array.map(Either.either(x => x->Tuple.snd2->Either.right, Either.right))

      switch change {
      | #Clear => {
        stateValues->Array.forEach(c => c.close())
        ( [], [], [], None )
      }
      | #Reset => {
        stateValues->Array.forEach(c => c.close())
        let (v, o, d) = makeDynInner(context, initial, set)
        // FIXME: Should be left with init?
        let d = d->Array.mapi((d, i) => Either.left((Array.getUnsafe(o, i), d)))
        (v, o, d, Some(v))
      }
      | #Add(value) =>  {
        let index = stateValues->Array.length
        let setElement = set->Dynamic.keepMap(Array.get(_, index))
        let {first, init, dyn} = F.makeDyn(context.element, value, setElement, None)
        let key = getKey()
        let first = packKeyValue(key, first)
        let init = packKeyObss(key, init)
        let dyn = packKeyDyns(key, dyn)
        let values = stateValues->Array.append(first)
        ( values
        , stateObs->Array.append(init)
        // Adding an element to an array, the init process has already gone off for the initial array
        // But we need to process the init on the child, so prepend to dyn.
        // FIXME: does this cause init to replay every time tye dyns are joined? YES
        , dyns->Array.append(Either.left((init, dyn)))
        , None //Some(values)
        )
      }
      | #Remove(index) => {
        stateValues->Array.get(index)->Option.forEach(c => c.close())
        let values = stateValues->Array.remove(index)
        ( values
        , stateObs->Array.remove(index)
        // Remove changes the structure of the array,
        // but does not cause any child element emissions,
        // so return values to the scan
        , dyns->Array.remove(index)
        , Some(values)
        )
      }
      | #Set(input) => {
        stateValues->Array.forEach(c => c.close())
        let (values, obs, dyns) = input->traverseSetk(context, set, _)->packKey

        ( values, obs, dyns->Array.map(Either.right), None)
      }}
    }, (firstInner, initInner, dynInner->Array.map(Either.right), None)))
    // The scan does not emit without a change,
    // but we want to prime the switch below to observe child changes
    // so startWith the same values as the scan initial
    ->Dynamic.startWith((firstInner, initInner, dynInner->Array.map(Either.right), None))
    ->Dynamic.switchMap( (((value, obs, dyns, prefix)):
        ( Array.t<Close.t<Form.t<(key, F.t), F.actions<unit>>>>
        , Array.t<Dyn.init<Close.t<Form.t<(key, F.t), F.actions<()>>>>>
        , Array.t
            < Either.t
              < (Dyn.init<Close.t<Form.t<(key, F.t), F.actions<unit>>>>, Dyn.dyn<Close.t<Form.t<(key, F.t), F.actions<()>>>>)
              , Dyn.dyn<Close.t<Form.t<(key, F.t), F.actions<()>>>>
              >
            >
        , Option.t<Array.t<Close.t<Form.t<(key, F.t), F.actions<unit>>>>>
        )
      ): Dyn.dyn<Array.t<Close.t<Form.t<(key, F.t), F.actions<()>>>>> => {

      // When the previous change introduced a new element, we want to prepend the initial validation
      // to the dynamic observable, but only the first time.
      // Each successive change in changes above will cast the existing dyns to Right.
      // This prevents the init from rerunning when we combineLatest in a later change
      let dyns = dyns->Array.map(Either.either(((i, d)) => d->Dynamic.startWith(i), y => y))

      // as successive observables come in from each child,
      // and we want to combineLatestScan them to make an observable for the array
      // We want to start with the latest values from the children
      // the values passed in are constant, so they become wrong after the first change
      // stateValues is wrong to start.
      // So lets have our own behavior observable to follow the values inside the context of this array change.
      let stateValuesInner =
        Rxjs.Subject.makeBehavior(value)
        ->Rxjs.pipe(Rxjs.distinct())

      let prefix = switch prefix {
        | Some(value) => Dynamic.startWith(_, Dynamic.return(value))
        | None => x => x
      }

      // FIXME: Delete will update the dyns array, but until another change happens,
      // the switchMap will not emit the new dyns array.
      // So the ui doesnt update
      // Add doesn't have this problem because we prefix the new element dyn with init
      // that *definitely* emits atleast the first value, which is enough to tickle this switchMap
      switch dyns {
      // When the array is empty, there are no events to animate the combineLatestScan
      // So a default for []
      | [] => Dynamic.return(Dynamic.return([]))
      | dyns => {
        dyns
        ->combineLatestScan(obs)
        ->Dynamic.tap(Rxjs.next(stateObs))
        // The values that comes in from the top of this switchMap will become outdated
        // as the dyns emit values.
        // Closing over it inside this nested combineLatestScan will introduce this old value into the stream.
        // at the start of each new inner observable which is per character in a FieldParse, for example.
        // So we need more recent values, can we take it directly with stateValues?
        // At the very beggining though, after #Add or #Remove, stateValues isnt correct either!
        ->Dynamic.withLatestFrom(stateValuesInner)
        ->Dynamic.map(((x, init)) => {
          combineLatestScan(x, init)
          ->Dynamic.tap(Rxjs.next(stateValuesInner))
        })
        ->prefix
      }}
    })

    let dyn =
      dynInner
      ->Dynamic.map(Dynamic.tap(_, Rxjs.next(stateValues)))
      ->Dynamic.switchMap(Dynamic.map(_, applyInner))
      ->Rxjs.pipe(Rxjs.takeUntil(complete))

    {first, init, dyn}
  }
}
