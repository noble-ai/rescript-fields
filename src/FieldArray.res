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

  let validateImpl = (context: context, force, inner) => {
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
  let makeStore = (~validate, inner: inner): Rxjs.t<Rxjs.foreign, Rxjs.void,t> => {
    [
      prefer(#Busy, Store.busy, inner),
      preferFiltered(#Invalid, Store.invalid(_, #Part), inner, inner->I.filter),
      preferFiltered(#Dirty, Store.dirty, inner, inner->I.filter),
      validate(inner),
    ]
    ->Array.reduce(Result.first, Error(#Invalid))
    ->Result.resolve(~ok=x => x, ~err=FieldVector.resolveErr(inner))
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

  let makeDynInit = (context: context, initial: option<input>, set: Rxjs.Observable.t<input>)
    : (
      Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>,
      Array.t<Dyn.dyn<Close.t<Form.t<F.t, F.actions<()>>>>>,
    )
   => {
      Option.first(initial, Option.flap0(context.empty))
      ->Option.or([])
      // THis is the same as #Set below
      ->Array.mapi( (value, index) => {
        let setElement = set->Dynamic.keepMap(Array.get(_, index))->Dynamic.startWith(value)
        let x = F.makeDyn(context.element, Some(value), setElement, None)
        (x.first, x.dyn)
      })
      ->Array.sequenceTuple
  }
 
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

  let makeDyn = (context: context, initial: option<input>, setOuter: Rxjs.Observable.t<input>, _validate: option<Rxjs.Observable.t<()>>)
    : Dyn.t<Close.t<Form.t<t, actions<()>>>>
  => {
    let (firstInner, dynInner) = makeDynInit(context, initial, setOuter)
    let packsInner = firstInner->Array.map(Close.pack)
    let actionsInner = packsInner->Array.map(Form.actions)
    let fieldsInner = packsInner->Array.map(Form.field) 

    let opt: Rxjs.t<'c, Rxjs.source<option<input>>, option<input>> = Rxjs.Subject.makeEmpty()
    let setInner: Rxjs.t<'c, Rxjs.source<input>, input> = Rxjs.Subject.makeEmpty()
    let clearInner = Rxjs.Subject.makeEmpty()
    let reset = Rxjs.Subject.makeEmpty()
    let add: Rxjs.t<'ca, Rxjs.source<option<F.input>>, option<F.input>> = Rxjs.Subject.makeEmpty()
    let remove: Rxjs.t<'cr, Rxjs.source<int>, int> = Rxjs.Subject.makeEmpty()
    let complete = Rxjs.Subject.makeEmpty()

    let setOpt = opt->Rxjs.pipe(Rxjs.keepMap(x => x))
    let clearOpt = opt->Rxjs.pipe(Rxjs.keepMap(Option.invert(_, ())))
    
    let clear = Rxjs.merge2(clearInner, clearOpt)

    let field = fieldsInner->Store.init

    let actions: actions<()> = {
      set: Rxjs.next(setInner),
      clear: Rxjs.next(clearInner),
      opt: Rxjs.next(opt),
      index: Array.get(actionsInner), 
      add: Rxjs.next(add),
      remove: Rxjs.next(remove),
      reset: Rxjs.next(reset),
    }

    let closeArray = () => { 
      clearInner->Rxjs.complete
      reset->Rxjs.complete
      add->Rxjs.complete
      remove->Rxjs.complete
      opt->Rxjs.complete
      setInner->Rxjs.complete
      complete->Rxjs.next()
    }

    let close = () => {
      firstInner->Array.forEach( c => c.close())
      closeArray()
    }

    let first: Close.t<Form.t<'f, 'a>> = {pack: {field, actions}, close}
    
    let stateElements = Rxjs.Subject.make(firstInner)
      ->Rxjs.pipe(Rxjs.shareReplay(1))

    let set = Rxjs.merge3(setOuter, setInner, setOpt)
      ->Rxjs.pipe(Rxjs.shareReplay(1))

    // multiplex all the various Array level change signals
    // So we can scan on them, producing new arrays of F.t dyns.  
    let changes = Rxjs.merge5(
      add->Dynamic.map(x => #Add(x)),
      remove->Dynamic.map(i => #Remove(i)),
      set->Dynamic.map(x => #Set(x)),
      clear->Dynamic.map(_ => #Clear),
      reset->Dynamic.map(_ => #Reset),
    )

    let elements = 
      changes
      ->Dynamic.withLatestFrom(stateElements->Dynamic.startWith(firstInner))
      // scan accumulates state, but only so it can be passed to the combineLatestArray step
      ->Rxjs.pipe(Rxjs.scan( 
        ( (firsts: Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>, dyns)
        , (change: 'change, stateElements: Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>)
        , _sequence)
      : ( Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>
        , Array.t<Dyn.dyn<Close.t<Form.t<F.t, F.actions<()>>>>>
        ) 
     => {
      switch change {
      | #Clear => {
        stateElements->Array.forEach(c => c.close())
        ( [], [] )
      }
      | #Reset => {
        stateElements->Array.forEach(c => c.close())
        makeDynInit(context, initial, set)
      }
      | #Add(value) =>  {
        let index = firsts->Array.length
        let setElement = set->Dynamic.keepMap(Array.get(_, index))
        let {first, dyn} = F.makeDyn(context.element, value, setElement, None)
        let dyn = dyn->Dynamic.startWith(Dynamic.return(first))
        ( stateElements->Array.append(first)
        , dyns->Array.append(dyn)
        )
      }
      | #Remove(index) => {
        stateElements->Array.get(index)->Option.forEach(c => c.close())
        
        ( stateElements->Array.remove(index)
        , dyns->Array.remove(index)
        )
      }
      | #Set(input) => {
        stateElements->Array.forEach(c => c.close())
        let (firsts, dyns) = 
          input 
          ->Array.mapi( (value, index) => {
            let setElement = set->Dynamic.keepMap(Array.get(_, index))->Dynamic.startWith(value)
            let x = F.makeDyn(context.element, Some(value), setElement, None)
            (x.first, x.dyn)
          })
          ->Array.sequenceTuple
        ( firsts
        , dyns
        )
      }}
    }, (firstInner, dynInner)))
    // Take the latest array of inner dyns, 
    ->Dynamic.withLatestFrom(stateElements->Dynamic.startWith(firstInner))
    ->Dynamic.switchMap( (((_firsts, dyns), stateElements): (
        ( Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>
        , Array.t<Dyn.dyn<Close.t<Form.t<F.t, F.actions<()>>>>>
        )
        , Array.t<Close.t<Form.t<F.t, F.actions<unit>>>>
      )): Dyn.dyn<Array.t<Close.t<Form.t<F.t, F.actions<()>>>>> => {

      // When the array is empty, there are no events to animate combineLatestArray
      // So a default for []
      switch dyns {
      | [] => Dynamic.return(Dynamic.return([]))
      | dyns => {
        dyns
        ->Rxjs.combineLatestArray
        ->Dynamic.map(Rxjs.combineLatestArray)
        // Needs to tickle the combine latest with an initial value so that removing an index will emit new values 
        ->Dynamic.map(Dynamic.startWith(_, stateElements))
      }}
    })

    let validate = validateImpl(context, false)

    // Combine the
    let dyn = 
      elements
      ->Dynamic.switchMap(elements => { 
        elements
        ->Dynamic.map( elements => {
          Rxjs.next(stateElements, elements)
          elements
          ->Array.map(e => e->Close.pack->Form.field)
          ->makeStore(~validate)
          ->Dynamic.map((field): Close.t<Form.t<'f, 'a>> => {
            let actions: actions<unit> = {
              ...actions,
              index: index => Array.get(elements, index)->Option.map(e => e->Close.pack->Form.actions),
            }

            let close = () => {
              elements->Array.forEach(c => c.close())
              closeArray()
            }

            {pack: {field, actions}, close}
          })
        })
      })
      ->Dynamic.startWith(Dynamic.return(first))
      ->Rxjs.pipe(Rxjs.shareReplay(1))
      ->Rxjs.pipe(Rxjs.takeUntil(complete))

    {first, dyn}
  }
}
