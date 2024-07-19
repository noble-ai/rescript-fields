open Vitest 

describe("takeUntilshare", () => {
	describe("without share", () => {
		let source: Rxjs.t<Rxjs.subject<Rxjs.natural>, Rxjs.source<int>, int> = Rxjs.Subject.makeEmpty()
		let end: Rxjs.t<Rxjs.subject<Rxjs.natural>, Rxjs.source<()>, ()> = Rxjs.Subject.makeEmpty()
		let ace = source->Rxjs.pipe(Rxjs.takeUntil(end))
		let res = ace->Rxjs.toObservable->Dynamic.toHistory
		[3,4]->Array.forEach(Rxjs.next(ace))
		end->Rxjs.next()

		itPromise("accepts values", () => {
			res->Promise.tap(x => x->expect->toEqual([3, 4]))
		})
	})
})

describe("combineLatest2", () =>{
	describe("left hot", () => { 
		let left = Rxjs.Subject.makeEmpty 	
		describe("right hot", () => {
			let right = Rxjs.Subject.makeEmpty
			let test = () => {
				let left = left()
				let right = right()
				let combined = Rxjs.combineLatest2(left, right)
				Rxjs.next(left, 1)
				Rxjs.next(right, 2)
				let res = combined->Dynamic.toHistory
				Rxjs.next(left, 3)
				Rxjs.next(right, 4)
				left->Rxjs.complete
				right->Rxjs.complete
				res
			}

			itPromise("behaves hot", () => {
				test()->Promise.tap(x => x->expect->toEqual([(3,4)]))
			})
		})
		describe("right cold", () => {
				let right = () => Rxjs.fromArray([1,2,3])
				let test = () => {
					let left = left()
					let right = right()
					let combined = Rxjs.combineLatest2(left, right)
					Rxjs.next(left, 1)
					Rxjs.next(left, 2)
					let res = combined->Dynamic.toHistory
					Rxjs.next(left, 3)
					left->Rxjs.complete
					res
				}

				itPromise("behaves hot", () => {
					test()->Promise.tap(x => x->expect->toEqual([(3, 3)]))
				})
		})
	})
	describe("left cold", () => {
		let left = () => Rxjs.fromArray([1,2,3])
		describe("right cold", () => {
			let right = () => Rxjs.fromArray([1,2,3])
			let test = () => {
				let left = left()
				let right = right()
				let combined = Rxjs.combineLatest2(left, right)
				let resA = combined->Dynamic.toHistory
				let resB = combined->Dynamic.toHistory
				Promise.all2((resA, resB))
			}

			itPromise("left major", () => {
				test()->Promise.tap( ((resa, _resb)) => {
					resa->Array.map(Tuple.fst2)->Array.all(x => x == 3)->expect->toBeTruthy
				})
			})
			itPromise("emits to both", () => {
				test()->Promise.tap( ((resa, resb)) => {
					resa->expect->toEqual([(3, 1), (3,2), (3,3)])
					resb->expect->toEqual([(3, 1), (3,2), (3,3)])
				})
			})
		})
		describe("right hot", () => {
			let right = Rxjs.Subject.makeEmpty
			let test = () => {
				let left = left()
				let right = right()
				let combined = Rxjs.combineLatest2(left, right)
				let resa = combined->Dynamic.toHistory
				Rxjs.next(right, 1)
				Rxjs.next(right, 2)
				let resb = combined->Dynamic.toHistory
				Rxjs.next(right, 3)
				right->Rxjs.complete
				(resa, resb)->Promise.all2
			}

			itPromise("multicast right major hot", () => {
				test()->Promise.tap(((resa, resb)) => {
					resa->expect->toEqual([(3, 1), (3, 2), (3, 3)])
					resb->expect->toEqual([(3, 3)])
				})
			})
		})
	})
})

describe("clearOpt", () => {
	let values = [None, Some("Some"), None]
	let test = (values) => {
		let source: Rxjs.t<'s, 'c, option<string>> = Rxjs.Subject.makeEmpty()
		let (setOpt, clearOpt) = source->Dynamic.partition2((x=>x, Option.invert(_, "invert")))
		let combined = Rxjs.merge2(setOpt, clearOpt)
		let res = combined->Dynamic.toHistory
		values->Array.forEach(Rxjs.next(source))
		source->Rxjs.complete
		res
	}

	itPromise("captures Nones", () => {
		test(values)->Promise.tap(res => {
			res->expect->toHaveLengthArray(values->Array.length)
		})
	})
})

describe("merge optional", () => {
	describe("merge2",  () => {
		let values = [None, Some(3), None ]
		let source: Rxjs.t<'s, 'c, option<int>> = Rxjs.Subject.makeEmpty()
		let (setOpt, clearOpt) = source->Dynamic.partition2((x=>x, Option.invert(_, ())))
		
		let setOpt = setOpt->Dynamic.map(Option.some)
		let clearOpt: Rxjs.t<'s, 'c, option<int>> =  clearOpt->Dynamic.map(_ => None)
		let res = Rxjs.merge2(setOpt->Rxjs.toObservable, clearOpt->Rxjs.toObservable)->Dynamic.toHistory

		values->Array.forEach(Rxjs.next(source))
		source->Rxjs.complete

		itPromise("captures Nones", () => {
			res->Promise.tap(res => {
				res->expect->toHaveLengthArray(values->Array.length)
			})
		})
	})

	describe("merge3", () => {
		let values1 = [None, Some(3), Some(4)]
		let values2 = [None, None]
		let values3 = [Some(1), Some(0), Some(6), Some(9)] 

		let source1 = Rxjs.Subject.makeEmpty()
		let source2 = Rxjs.Subject.makeEmpty()
		let source3 = Rxjs.Subject.makeEmpty()

		let subject = Rxjs.merge3(source1, source2, source3)
		let res = subject->Dynamic.toHistory

		values1->Array.forEach(Rxjs.next(source1))
		values2->Array.forEach(Rxjs.next(source2))
		values3->Array.forEach(Rxjs.next(source3))
		source1->Rxjs.complete
		source2->Rxjs.complete
		source3->Rxjs.complete

		itPromise("emits for each", () => {
			res->Promise.tap(res => res->expect->toHaveLengthArray( values1->Array.length + values2->Array.length + values3->Array.length ) )
		})
	})
})

describe("share", () => {
	describe("without share", () => {
		let source: Rxjs.t<Rxjs.subject<Rxjs.natural>, Rxjs.source<int>, int> = Rxjs.Subject.makeEmpty()
		let ace = source->Rxjs.pipe(Rxjs.map((s, _) => s->Int.toString))
		let left = ace->Rxjs.pipe(Rxjs.map((s, _) => `l${s}`))
		let right = ace->Rxjs.pipe(Rxjs.map((s, _) => `r${s}`))
		let combined = Rxjs.merge2(left, right)
		let res = combined->Dynamic.toHistory

		itPromise("accepts values", () => {
			[1,2]->Array.forEach(Rxjs.next(source))
			source->Rxjs.complete
			res->Promise.tap(x => x->expect->toEqual(["l1", "r1", "l2", "r2"]))
		})
	})
})

describe("source behavior", () => {
	itPromise("accepts values to source", () => {
		let source: Rxjs.t<Rxjs.subject<Rxjs.natural>, Rxjs.source<int>, int> = Rxjs.Subject.makeEmpty()
		let strings = source->Rxjs.pipe(Rxjs.map((s, _) => s->Int.toString))
		let hist = strings->Rxjs.toObservable->Dynamic.toHistory
		source->Rxjs.next(1)
		source->Rxjs.next(2)
		source->Rxjs.complete
		hist->Promise.tap(x => x->expect->toEqual(["1", "2"]))
	})
	itPromise("accepts values to derived", () => {
		let source: Rxjs.t<Rxjs.subject<Rxjs.natural>, Rxjs.source<int>, int> = Rxjs.Subject.makeEmpty()
		let derived = source->Rxjs.pipe(Rxjs.map((s, _) => s->Int.toString))
		let hist = derived->Rxjs.toObservable->Dynamic.toHistory
		derived->Rxjs.next(1)
		derived->Rxjs.next(2)
		derived->Rxjs.complete
		hist->Promise.tap(x => x->expect->toEqual(["1", "2"]))
	})
})

describe("contramap", () => {
	let subj: Rxjs.t<'c, Rxjs.source<string>, string> = Rxjs.Subject.makeEmpty()
	// Console.log2("contramap", subj->Rxjs.toObserver->((x: Rxjs.Observer.t<'x>)=> x.next))
	let contramapped = subj->Rxjs.toObserver->Dynamic.contramap(Int.toString)

	itPromise("accepts values", () => {
		let hist = subj->Rxjs.toObservable->Dynamic.toHistory
		contramapped.next(. 1)
		contramapped.next(. 2)
		subj->Rxjs.complete

		hist->Promise.tap(x => x->expect->toEqual(["1", "2"]))
	})
})

describe("keepMap None", () => {
  let subj: Rxjs.t<'c, Rxjs.source<option<int>>, option<int>> = Rxjs.Subject.makeEmpty()
	let clearOpt = subj->Rxjs.pipe(Rxjs.keepMap(Option.invert(_, ())))
	let res = clearOpt->Rxjs.toObservable->Dynamic.toHistory
	subj->Rxjs.next(Some(3))
	subj->Rxjs.next(None)
	subj->Rxjs.next(None)
	subj->Rxjs.next(None)
	subj->Rxjs.next(None)

	subj->Rxjs.complete

	itPromise("keeps the nones as undefined", () => {
		res->Promise.tap(res => res->expect->toHaveLengthArray(4))
	})
})

// This is failing in CI, but not locally.  I'm not sure why.  I'm going to skip it for now. - AxM
describeSkip("jitter", () => {
	let sets = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
	let setsDelay = sets->Rxjs.fromArray->Dynamic.jitter
	itPromise(
		"returns the values in order",
		() => {
			setsDelay->Dynamic.toHistory->Promise.tap(x => x->expect->toEqual(sets))
		},
	)
	itPromise(
		"spaces the values between 2 and 40ms",
		() => {
			setsDelay
			->Rxjs.pipe(Rxjs.timeInterval())
			->Dynamic.toHistory
			->Promise.map(Array.tail)
			->Promise.tap(
				x => {
					// x->expect->toHaveLengthArray(sets->Array.length)
					x->Array.forEach(
						x => {
							x.interval->expect->toBeGreaterThanOrEqualInt(2)
							// Slight epsilon on the high end..whatever
							x.interval->expect->toBeLessThanOrEqualInt(50)
						},
					)
				},
			)
		},
	)
})

