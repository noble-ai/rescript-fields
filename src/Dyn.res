@@ocamldoc("
Rxjs Observables are not guaranteed to emit any values
Let alone begin with a value (on connection?)
BehaviorSubjects will, but its unclear that mapping and other transformations on
a BehaviorSubject produce a BehaviorSubject.
Observables can also be modified with beginsWith, or replay that allow this behavior
on Observables that are not BehaviorSubject.
And then even for these observables that do emit at start, you have to operate inside of that
observable chain which may leave some clients waiting one or more ticks for a value
and will cause the resultant types to be option<'value> in lots of places where we 
we can be sure it has a value
So lets build and maintain the Dyn type t which has a first value along side an observable.
in the style of NonEmptyList etc. 

One detail since we are using this for Field makeDyn only, and we want to be operating on Observable of Observable everywhere,
lets bake that into the dyn type as dyn<'t>
")

type dyn<'a> = Rxjs.Observable.t<Rxjs.Observable.t<'a>>

@deriving(accessors)
type t<'a> = { first: 'a, dyn: dyn<'a> }

let map = (d, fn) => {
	first: d.first->fn,
	dyn: d.dyn->Rxjs.pipe(Rxjs.map((x, _i) => x->Rxjs.pipe(Rxjs.map((x, _i) => fn(x)))))
}
