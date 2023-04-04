open Rxjs

let applyLatest = (~setfield, ~subject, a) =>
  a->pipe(
    Rxjs.tap(f => {
      next(subject, f)
      setfield(_ => f)
    }),
  )

let applyUpdate = (~onUpdate=?, a) => {
  a->pipe(tap(e => onUpdate->Option.flap1(e)->Option.void))
}

let applyComplete = (~onComplete=?, a) => {
  a->pipe(
    tap(e => {
      onComplete->Option.flap1(e)->Option.void
    }),
  )
}

// For a stream of any type of values,
// and a constant value and index
// send the index value pair to out.
// This is used in maintaining the map of outstanding changes
let applyOut = (~value, ~index, ~out: t<'c, source<(int, 'a)>, 'o>, a) =>
  a->pipe(tap(_ => out->next((index, value))))

// send the subject stream to F.reduce
// which should take one value (producing a cold observer), that yields one or many new values for the field.
// This also applies latest to subject and field,
// which can be drawn from to merge overlapping updates
// with the most recent value.
// And sends notifications for each update and the final value
// and then sends an event to output for tracking
// the active changes.
let applyChange = (
  ~reduce,
  ~subject,
  ~setfield,
  ~changeOut,
  index,
  (change, onUpdate, onComplete) as ch,
) => {
  subject
  ->toObservable
  ->reduce(_, change)
  ->applyLatest(~setfield, ~subject)
  ->applyUpdate(~onUpdate)
  ->pipe(last())
  ->applyComplete(~onComplete)
  ->applyOut(~value=ch, ~index, ~out=changeOut)
}

// Take the latest value of validation stream
// send to F.validate
// and apply values similar to above
// Not tracking activeValidates yet
// since they are pretty much blocking
// so no applyOut
let applyValidate = (~validate, ~subject, ~context, ~setfield, (onUpdate, onComplete)) => {
  subject
  ->toObservable
  ->pipe(take(1))
  ->pipe(
    concatMap(field => {
      validate(false, context, field)
      ->applyLatest(~setfield, ~subject)
      ->applyUpdate(~onUpdate)
      ->pipe(last())
      ->applyComplete(~onComplete)
      // ->applyOut(~value=ch, ~index, ~out=changeOut)
    }),
  )
}

// Wrap each value in a tuple containing the index value
// so that products of these events can be grouped and ordered.
let keyByIndex = a => a->pipe(map(.(x, i) => (i, x)))

// Given a sequence of additions, and removals
// Emit a map of existing values.
// Removals may come out of order,
// but adds must come before removes
let scanActive = (add: Rxjs.t<'ca, 'sa, (int, 'a)>, remove: Rxjs.t<'cr, 'sr, (int, 'a)>) => {
  merge2(add->pipe(map(.(x, _) => #In(x))), remove->pipe(map(.(x, _) => #Out(x))))->pipe(
    scan((acc, curr, _index) => {
      switch curr {
      | #In(index, val) => acc->Belt.Map.Int.set(index, val)
      | #Out(index, _val) => acc->Belt.Map.Int.remove(index)
      }
    }, Belt.Map.Int.empty),
  )
}

let traverseIndexed = (toInner, (i: int, x)) => x->toInner->Option.map(ch => (i, ch))

module Make = (F: FieldTrip.Field) => {
  type input = F.input
  type output = F.output
  type context = F.context

  type reduce = (
    ~onChange: F.t => unit=?,
    ~onComplete: F.t => unit=?,
    F.change,
  ) => unit

  type return = {
    field: F.t,
    input: F.input,
    output: option<F.output>,
    reduce: reduce,
    reducePromise: F.change => Js.Promise.t<F.t>,
    validate: (~onChange: F.t => unit, ~onComplete: F.t => unit) => unit,
    validatePromise: unit => Js.Promise.t<F.t>,
    // gate submission on valid data
    handleSubmit: (F.output => Js.Promise.t<unit>, ReactEvent.Form.t) => unit,
    handleOutput: (F.output => Js.Promise.t<unit>) => unit,
  }

  type change = (F.change, F.t => unit, F.t => unit)
  type validate = (F.t => unit, F.t => unit)
  type submit = F.output => Js.Promise.t<unit>
  type operation = [
    | #Validate(validate)
    | #Change(change)
  ]

  // To maintain the sequence of changes,
  // we are merging validates and changes  into a single stream before indexing,
  // but then need to split them apart again to apply each correctly.
  // These are helpers to pick out each one
  let toValidate: [> #Validate('a)] => option<'a> = o => {
    switch o {
    | #Validate(validate) => Some(validate)
    | _ => None
    }
  }

  let toChange: [> #Change('a)] => option<'a> = o => {
    switch o {
    | #Change(change) => Some(change)
    | _ => None
    }
  }

  // guard submit handler on the valid state of the field
  let onCompleteOutput = (fn: submit, field) => {
    field->F.output->Option.tap(output => output->fn->Promise.void)->Option.void
  }

  let use = (~context, ~init: option<F.input>=?, ~validateInit=false, ()) => {
    // field is the latest known state of the field.
    // There may be outstanding promises that will resolve and change this value
    // This is initialized directly from init, and promise is initialized from field,
    // but the dependency is the other direction from there on.
    let (field, setfield) = React.useState(_ =>
      init->Option.map(F.set)->Option.getWithDefault(F.init(context))
    )

    // we want to keep the last context for application
    // with successive operations, and it starts with a value.
    // So use BehaviorSubject
    // juggling the name context here so we can keep using the full one
    let ctx = context
    let context: React.ref<t<'c, 's, context>> = React.useRef(BehaviorSubject.make(context))

    // send the new value into the context observable
    // any time the input context changes.
    // THIS CAN BE HIGHLY VOLATILE
    // without any guarantee that the context is memoized or constant
    // specifically when you are dealing with form input
    // and causing rerenders
    // so be careful to not use this with `combineLatest` etc

    React.useEffect1(() => {
      context.current->next(ctx)
      None
    }, [ctx])

    // Subject is the Reactive equivalent of field.
    let subject = React.useRef(BehaviorSubject.make(field))

    // we want change to maintain its last value
    // but it doesnt begin with a value
    // So use Subject
    let change: React.ref<t<subject, source<change>, change>> = React.useRef(Subject.makeEmpty())

    // changeOut is used with 'changeIn' to keep track of the changes in flight.
    // I have exposed changes as subject without index for ingress,
    // since the indexing also includes valdiations
    // but changes are mapped into these indexed tuples as well below
    let changeIn: React.ref<t<subject, source<(int, change)>, (int, change)>> = React.useRef(
      Subject.makeEmpty(),
    )

    let changeOut: React.ref<t<subject, source<(int, change)>, (int, change)>> = React.useRef(
      Subject.makeEmpty(),
    )

    let validate: React.ref<t<subject, 'sv, validate>> = React.useRef(Subject.makeEmpty())

    React.useEffect1(() => {
      // Keep derived observables here inside the same effect scope
      // Keep a map of outstanding changes by index

      // With a stream of changes being intiated
      // and a stream of changes being finished
      // we can know at any time what changes are in flight
      // But have no value before the first event
      // so add "startWith", to give it initial value
      // used for validateSignal below
      let changesActive =
        scanActive(changeIn.current, changeOut.current)->pipe(startWith(Belt.Map.Int.empty))

      // Since we know every time the set of active changes changes
      // we can emit an event every time the changes becomes empty
      let emptyChangesActive =
        changesActive->pipe3(map(.(x, _) => x->Belt.Map.Int.size), filter(x => x == 0), const())

      // We want to prevent validations from being applied
      // while there are other changes in flight
      // since the output from the validation is
      // depended on for enabling form outputs etc.
      // So make a signal that will emit
      // when a validate event arrives and there are no outstanding changes.
      // or the outstanding changes list becomes empty
      let validateSignal = merge2(
        validate.current->pipe3(
          withLatestFrom(changesActive),
          filter(((_v, c)) => c->Belt.Map.Int.size == 0),
          const(),
        ),
        emptyChangesActive,
      )

      // Buffer the validation stream until
      // the validation queue is clear
      // and take the most recent one.
      // TODO this is probably a debounce call, actually.
      let validateBuffered = validate.current->pipe3(
        buffer(validateSignal),
        filter(x => x->Js.Array2.length > 0),
        // Can getExn since we filter length above
        map(.(vs, _i) => vs->Array.last->Option.getExn(~desc="validateBuffered")),
      )

      // Combine change and validate actions into a single stream
      // so they can be indexed, and later use that index to
      // bias for later changes etc.
      let operation =
        merge2(
          change.current->pipe(map(.(ch, _) => #Change(ch))),
          validateBuffered->pipe(map(.(v, _) => #Validate(v))),
        )->keyByIndex

      // hook changeIn back to operation,
      // which is an input to the validation stream buffering.
      // This is the point where a cycle is created
      let subscriptionChangeIn =
        operation->pipe(keepMap(traverseIndexed(toChange)))->subscribe(changeIn.current)

      // Reseparate changes and validations and apply them in order.
      let applyOperation = (
        context: context,
        operation: (int, operation),
        subject: t<'class, source<'a>, F.t>,
      ) => {
        switch operation {
        | (index, #Change(ch)) =>
          applyChange(
            ~reduce=F.reduce(~context),
            ~subject,
            ~setfield,
            ~changeOut=changeOut.current,
            index,
            ch,
          )
        | (_index, #Validate(v)) =>
          applyValidate(~validate=F.validate, ~subject, ~context, ~setfield, v)
        }
      }

      // make the ultimate stream of changes applied with context
      let execution =
        operation
        // Each change happens with a constant context
        // the latest one up to this point
        ->pipe(withLatestFrom(context.current))
        ->pipe(
          mergeMap(((operation, context)) => applyOperation(context, operation, subject.current)),
        )

      let subscriptionExecution =
        execution->subscribe(
          Observer.make(~next=Void.void, ~error=Void.void, ~complete=Void.void, ()),
        )

      // The relationship of fieldTrip init state and running state
      // isnt fully fleshed out yet. I dont feel like init changing should trump user input
      // but maybe init changing on an untouched input should be applied?
      // This would require a little bit of deep comparison and yeah.
      // So for now we only take the first init value and only validate it once. - AxM
      if validateInit {
        validate.current->next((Void.void, Void.void))
      }

      Some(
        () => {
          unsubscribe(subscriptionChangeIn)
          unsubscribe(subscriptionExecution)
        },
      )
    }, [])

    let mounted = React.useRef(true)

    let input = React.useMemo1(_ => F.input(field), [field])
    let output = React.useMemo1(_ => F.output(field), [field])

    let handleSubmit = React.useMemo1(() => {
      (fn: F.output => Js.Promise.t<unit>) => {
        let onComplete = onCompleteOutput(fn)

        e => {
          e->ReactEvent.Form.preventDefault
          // inside of the promise context
          validate.current->next((Void.void, onComplete))
        }
      }
    }, [])

    let handleOutput = React.useMemo1( () => 
      (fn: F.output => Js.Promise.t<unit>) => {
        let onComplete = onCompleteOutput(fn)
        // inside of the promise context
        validate.current->next((Void.void, onComplete))
      }, [])

    let validate = React.useMemo(((), ~onChange, ~onComplete) =>
      validate.current->next((onChange, onComplete))
    )

    let validatePromise = React.useMemo1(() => {
      () =>
        Js.Promise.make((~resolve, ~reject) => {
          ignore(reject)
          validate(~onChange=Void.void, ~onComplete=a => resolve(. a))
        })
    }, [validate])

    React.useEffect1(() => {
      mounted.current = true
      Some(() => mounted.current = false)
    }, [])

    let reduce: reduce = React.useMemo(() => {
       ( 
          ~onChange: option<F.t => unit>=?,
          ~onComplete: option<F.t => unit>=?,
          cha,
        ) => {
          let onChange = onChange->Option.getWithDefault(Void.void)
          let onComplete = onComplete->Option.getWithDefault(Void.void)
          let c: change = (cha, onChange, onComplete)
          change.current->next(c)
        }
    })

    // Convenience to promisify reduce when we are only concerned with the final value
    let reducePromise = React.useMemo1(() => {
      ch =>
        Js.Promise.make((~resolve, ~reject) => {
          ignore(reject)
          reduce(~onChange=Void.void, ~onComplete=a => resolve(. a), ch)
        })
    }, [reduce])

    {
      field: field,
      input: input,
      output: output,
      reduce: reduce,
      reducePromise: reducePromise,
      validate: validate,
      validatePromise: validatePromise,
      handleSubmit: handleSubmit,
      handleOutput: handleOutput,
    }
  }
}
