import { describe, it, expect } from 'vitest'
import { fromTuple, fromTupleExample, toTuple } from './ProductGeneric'

// type structure<'a, 'b>

    // let fromTuple: (('a, 'b)) => structure<'a, 'b>
    // let order: (structure<'a, 'b> => 'a, structure<'a, 'b> => 'b)

describe('fromTupleExample', () => {
	describe('for some object', () => {
		const obj = {a: undefined, x: "world", b: 3}
		const order = [x => x.a, x => x.x, x => x.b]
		let values = ["A", "X", "B"]
		let res = fromTupleExample(obj, order, values)

		it('should zip', () => {
			expect(res).toEqual({a: "A", x: "X", b: "B"})
		})
	})
})

describe('ProductGeneric', () => {
	describe('for some object', () => {
		const obj = {a: "hello", x: "world", b: 3}
		const tuple = toTuple(obj)
		const obj2 = fromTuple(tuple)

		it('round trips', () => {
			expect(obj2).toEqual(obj)
		})
	})
})
