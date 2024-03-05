open Vitest
 
describe("Priorities", () => {
	let priorities = [2, 0, 2, 3, 1]
	let indices  = priorities->Array.length->Array.range
	let res = Lodash.zip2Equal(priorities, indices)
		->Array.reduce((acc, (priority, index)) => acc->Priorities.apply(priority, index), Priorities.empty())

	it("priority 2 overriden by 1", () => res->Priorities.get(2)->expect->toEqual(Some(4)))
	it("priority 0 never impacted by others", () => res->Priorities.get(0)->expect->toEqual(None))
	it("priority 3 overriden by 1", () => res->Priorities.get(3)->expect->toEqual(Some(4)))
	it("priority 1 overriden by 0", () => res->Priorities.get(1)->expect->toEqual(Some(1)))
})