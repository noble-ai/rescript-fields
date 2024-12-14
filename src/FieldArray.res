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

external identity: 'a => 'a = "%identity"

let mergeCloses = (closes) => {
  () => {
    closes->Array.forEach(x => x())
  }
}

let mergeInner =  (array: array<Close.t<Form.t<'fa, 'aa>>>): Close.t<Form.t<'f, 'a>> => {
  let field = array->Array.map(x => x.pack.field)
  let actions = array->Array.map(x => x.pack.actions)
  let close = mergeCloses(array->Array.map(x => x.close))
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
  let filter: array<t> => array<t>
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
    and type inner = array<F.t>
    and type output = array<F.output>
    and type error = error
    and type t = Store.t<array<F.t>, array<F.output>, error>
    and type context = Context.structure<F.output, F.context, F.input>
    and type actions<'change> = actions<F.input, F.actions<'change>, 'change>
    and type parted = array<Form.t<F.t, F.actions<()>>>

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
  type inner = array<Element.t>
  type t = Store.t<inner, output, error>

  let empty: context => inner = (context) => Option.flap0(context.empty)->Option.or([])->Array.map(F.set)
  let init: context => t = context => context->empty->Store.init

  let set = (input: input): t => input->Array.map(F.set)->Dirty

  let makeOutput = (inner: inner): Result.t<array<F.output>, 'err> =>
    inner->Array.reduce((res, element) => {
      switch element->F.output {
      | Some(output) => res->Result.bind(res => Ok(Array.concat(res, [output])))
      | None => Error(element->F.enum)
      }
    }, Ok([]))

  let prefer = (enum, make, inner): Result.t<'a, 'e> =>
    // First Prioritize Busy first if any children are busy
    Result.predicate(
      inner->Array.map(Element.enum)->Array.some(x => x == enum),
      make(inner)->Dynamic.return,
      #Invalid,
    )

  let preferFiltered = (enum, make, inner, filtered): Result.t<'a, 'e> =>
    // First Prioritize Busy first if any children are busy
    Result.predicate(
      filtered->Array.map(Element.enum)->Array.some(x => x == enum),
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
      ->Array.map(Element.validate(force, context.element))
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

  type parted = array<Form.t<F.t, F.actions<()>>>
  let split = (pack: Form.t<t, actions<()>>): parted => {
    pack.field
    ->Store.inner
    ->Array.mapi( (field, i): Form.t<F.t, F.actions<()>> => {
      field,
      actions: pack.actions.index(i)->Option.getExn(~desc="fieldArray split"), 
    })
  }

  let enum = Store.toEnum

  let inner = Store.inner

  let input = (store: t) => {
    store->Store.inner->Array.map(Element.input)
  }

  let error = Store.error

  let output = Store.output

  let printErrorInner = (inner: inner) => {
    inner
    ->Array.map(F.printError)
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
        ${store->Store.inner->Array.map(Element.show)->Array.joinWith(",\n")}
      ]
    }`
  }

  let traverseSet = (context: context, set, x) => {
    x
    ->Array.mapi( (value, index) => (value, index))
    ->traverseTuple3( ((value, index)) => {
      let setElement = set->Dynamic.keepMap(Array.get(_, index))->Dynamic.startWith(value)
      let {first, init, dyn} = F.makeDyn(context.element, Some(value), setElement, None)
      (first, init, dyn)
    })
  }

  let makeDynInner = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>)
    : (
      Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>,
      Array.t<Dyn.init<Close.t<Form.t<F.t, F.actions<unit>>>>>,
      Array.t<Dyn.dyn<Close.t<Form.t<F.t, F.actions<()>>>>>,
    )
   => {
      Option.first(initial, Option.flap0(context.empty))
      ->Option.or([])
      ->traverseSet(context, set, _)
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

    // CLose this array completely. Maybe overkill
    let closeArray = () => {
      // Only static observables here
      Rxjs.complete(clearInner)
      Rxjs.complete(reset)
      Rxjs.complete(add)
      Rxjs.complete(remove)
      Rxjs.complete(opt)
      Rxjs.complete(setInner)
      Rxjs.next(complete, ())
    }


    let makeClose = (close: () => ()) => () => {
      close()
      closeArray()
    }

    let applyField = ({pack,close}: Close.t<Form.t<'aaf, 'baf>>) =>
          (field): Close.t<Form.t<t, actions<()>>> =>
            { pack:
              { field
              , actions: makeActions(pack.actions)
              }
            , close: makeClose(close)
            }

    let (firstInner, initInner, dynInner) = makeDynInner(context, initial, setOuter)

    // This is like applyInner but does not include makeStore which produces an observable.
    // We want one definite value, and now.
    let first: Close.t<Form.t<'ff, 'af>> = {
      let inners = mergeInner(firstInner)
      inners.pack.field
      ->Store.init
      ->applyField(inners, _)
    }

    let applyInner = (inners): Rxjs.Observable.t<Close.t<Form.t<t, actions<()>>>> => {
        let inners = mergeInner(inners)
        inners.pack.field
        ->makeStore(~validate=validateImpl(context, false))
        ->Dynamic.map(applyField(inners))
      }

    let stateValues =
      Rxjs.Subject.make(firstInner)

    let stateObs =
      Rxjs.Subject.make(initInner)

    let init = {
      combineLatestScan(initInner, firstInner)
      ->Dynamic.tap(Rxjs.next(stateValues))
      ->Dynamic.switchMap(applyInner)
    }

    let set =
      Rxjs.merge3(setOuter, setInner, setOpt)
    let clear = Rxjs.merge2(clearInner, clearOpt)

    // multiplex all the various Array level change signals
    // So we can scan on them, producing new arrays of F.t dyns.
    let elements =
      Rxjs.merge5(
        add->Dynamic.map(x => #Add(x)),
        remove->Dynamic.map(i => #Remove(i)),
        set->Dynamic.map(x => #Set(x)),
        clear->Dynamic.const(#Clear),
        reset->Dynamic.const(#Reset),
      )
      ->Dynamic.withLatestFrom2(
          // FIXME: Why do these have a startsWith if they are Behaviors?
          stateValues->Dynamic.startWith(firstInner)
          , stateObs->Dynamic.startWith(initInner)
          )
      ->Rxjs.pipe(Rxjs.scan(
        // The persistent values and obs are ignored in this scan,
        // As they can have changed outside of the scan
        // So we take stateValues and stateObs instead
        // then those can be passed to the combineLatestArray step
        // The observables may be the same but the values definitely can have changed
        // So ignore both to be consistent
        ( ( _values: Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>, _obs, dyns)
        , ( change: 'change
          , stateValues: Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>
          , stateObs: Array.t<Rxjs.Observable.t<Close.t<Form.t<F.t, F.actions<unit>>>>>
          )
        , _sequence)
      : ( Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>
        , Array.t<Dyn.init<Close.t<Form.t<F.t, F.actions<unit>>>>>
        , Array.t<Dyn.dyn<Close.t<Form.t<F.t, F.actions<()>>>>>
        )
     => {
      switch change {
      | #Clear => {
        stateValues->Array.forEach(c => c.close())
        ( [], [], [] )
      }
      | #Reset => {
        stateValues->Array.forEach(c => c.close())
        makeDynInner(context, initial, set)
      }
      | #Add(value) =>  {
        let index = stateValues->Array.length
        let setElement = set->Dynamic.keepMap(Array.get(_, index))
        let {first, init, dyn} = F.makeDyn(context.element, value, setElement, None)

        let obs = stateObs->Array.append(init)

        // Adding an element to an array, the init process has already gone off for the initial array
        // But we need to process the init on the child, so prepend to dyn.
        let dyn = dyn->Dynamic.startWith(init)

        ( stateValues->Array.append(first)
        , obs
        , dyns->Array.append(dyn)
        )
      }
      | #Remove(index) => {
        stateValues->Array.get(index)->Option.forEach(c => c.close())

        ( stateValues->Array.remove(index)
        , stateObs->Array.remove(index)
        , dyns->Array.remove(index)
        )
      }
      | #Set(input) => {
        stateValues->Array.forEach(c => c.close())
        let (values, obs, dyns) = input->traverseSet(context, set, _)
        ( values, obs, dyns)
      }}
    }, (firstInner, initInner, dynInner)))
    // The scan does not emit without a change,
    // but we want to prime the switch below to observe child changes
    // so startWith the same values as the scan initial
    ->Dynamic.startWith((firstInner, initInner, dynInner))
    ->Dynamic.tap( ((_, obs, _)) => Rxjs.next(stateObs, obs))
    ->Dynamic.switchMap( (((value, obs, dyns)):
        ( Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>
        , Array.t<Dyn.init<Close.t<Form.t<F.t, F.actions<()>>>>>
        , Array.t<Dyn.dyn<Close.t<Form.t<F.t, F.actions<()>>>>>
        )
      ): Dyn.dyn<Array.t<Close.t<Form.t<F.t, F.actions<()>>>>> => {

      switch dyns {
      // When the array is empty, there are no events to animate combineLatestArray
      // So a default for []
      // FIXME: there is no more combineLatestArray, is this still needed?
      | [] => Dynamic.return(Dynamic.return([]))
      | dyns => {
        dyns
        ->combineLatestScan(obs)
        ->Dynamic.tap(Rxjs.next(stateObs))
        ->Dynamic.map(combineLatestScan(_, value))
      }}
    })

    let dyn =
      elements
      ->Dynamic.switchMap(elements => {
        elements
        ->Dynamic.tap(Rxjs.next(stateValues))
        ->Dynamic.map(applyInner)
      })
      ->Rxjs.pipe(Rxjs.takeUntil(complete))

    {first, init, dyn}
  }
}
