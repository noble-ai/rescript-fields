// Utility for making a more generic generic for products.
// Stores the supplied field name wiwth the value in the tuple,
// and reproduces the object with those keys.

// With a record holding unknown values
// And an order of accessors into that record
// Can map record into record of names
// can get order of names
// Can zip ordered names with values
// can reproduce object with new values

export const fromTupleExample = (r, order, t) => {
      return Object.fromEntries(
            Object.entries(r).map(([k, v], i) => [k, t[i]])
      )
}

export const fromTuple = (t) => Object.fromEntries(t.map(([k, v]) => v))
export const toTuple = (x) => {
      // nap find lower case letter alphabetically by index
      const a = "a".codePointAt(0)
      return Object
      .entries(x)
      .sort( ([k, v], [kb, vb]) => k.localeCompare(kb))
      .map(([k, v], i) => [String.fromCodePoint(a+i), [k, v]])
      }

 