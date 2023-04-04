@val external describe: (string, unit => unit) => unit = "describe"
@val external describeOnly: (string, unit => unit) => unit = "describe.only"
@val external describeSkip: (string, unit => unit) => unit = "describe.skip"

//rescript seems to let return values bleed when weve cast it to unit and it bothers jest, so lets be sure? -AxM
let describe = (str, fn) =>
  describe(str, () => {
    fn()
    ()
  })

let describeOnly = (str, fn) =>
  describeOnly(str, () => {
    fn()
    ()
  })

let describeSkip = (str, fn) =>
  describeSkip(str, () => {
    fn()
    ()
  })


type expect<'a>
@val external expect: 'a => expect<'a> = "expect"
//     expect.extend(matchers)

@send external anything: expect<'a> => unit = "anything"
// @send external any(constructor)
@send external arrayContaining: (expect<array<'a>>, array<'a>) => unit = "arrayContaining"
@send external assertions: (expect<'a>, int) => unit = "assertions"
@send external hasAssertions: expect<'a> => unit = "hasAssertions"
// @send external not.arrayContaining(array)
// @send external not.objectContaining(object)
// @send external not.stringContaining(string)
// @send external not.stringMatching(string | regexp)
@send external objectContaining: (expect<'a>, 'b) => unit = "objectContaining"
@send external stringContaining: (expect<string>, string) => unit = "stringContaining"
@send external stringMatchingString: (expect<string>, string) => unit = "stringMatching"
@send external stringMatchingRe: (expect<string>, Js.Re.t) => unit = "stringMatching"
// @send external addSnapshotSerializer(serializer)
@get external not: expect<'a> => expect<'a> = "not"
@get external resolves: expect<Js.Promise.t<'a>> => expect<'a> = "resolves"
// @send external rejects
@send external toBe: (expect<'a>, 'a) => unit = "toBe"
@send external toBeCalled: expect<'a => 'b> => unit = "toBeCalled"
@send external toBeCalledTimes: (expect<'a => 'b>, int) => unit = "toBeCalledTimes"
// @send external toHaveBeenCalledWith(arg1, arg2, ...)
// @send external toHaveBeenLastCalledWith(arg1, arg2, ...)
// @send external toHaveBeenNthCalledWith(nthCall, arg1, arg2, ....)
// @send external toHaveReturned()
// @send external toHaveReturnedTimes(number)
// @send external toHaveReturnedWith(value)
// @send external toHaveLastReturnedWith(value)
// @send external toHaveNthReturnedWith(nthCall, value)
@send external toHaveLengthArray: (expect<array<'a>>, int) => unit = "toHaveLength"
@send external toHaveLengthString: (expect<string>, int) => unit = "toHaveLength"
// @send external toHaveProperty(keyPath, value?)
@send external toBeCloseTo: (expect<float>, float, int) => unit = "toBeCloseTo"
// @send external toBeDefined()
@send external toBeFalsy: expect<bool> => unit = "toBeFalsy"
@send external toBeGreaterThanFloat: (expect<float>, float) => unit = "toBeGreaterThan"
@send external toBeGreaterThanInt: (expect<int>, int) => unit = "toBeGreaterThan"
@send
external toBeGreaterThanOrEqualFloat: (expect<float>, float) => unit = "toBeGreaterThanOrEqual"
@send external toBeGreaterThanOrEqualInt: (expect<int>, int) => unit = "toBeGreaterThanOrEqual"
@send external toBeLessThanFloat: (expect<float>, float) => unit = "toBeLessThan"
@send external toBeLessThanInt: (expect<int>, int) => unit = "toBeLessThan"
@send external toBeLessThanOrEqualFloat: (expect<float>, float) => unit = "toBeLessThanOrEqual"
@send external toBeLessThanOrEqualInt: (expect<int>, int) => unit = "toBeLessThanOrEqual"
// @send external toBeInstanceOf(Class)
@send external toBeNull: expect<Js.Undefined.t<'a>> => unit = "toBeNull"
@send external toBeTruthy: expect<bool> => unit = "toBeTruthy"
// @send external toBeUndefined()
@send external toBeNaN: expect<float> => unit = "toBeNaN"
@send external toContain: (expect<array<'a>>, 'a) => unit = "toContain"
@send external toContainEqual: (expect<array<'a>>, 'a) => unit = "toContainEqual"
@send external toEqual: (expect<'a>, 'a) => unit = "toEqual"
@send external toMatchString: (expect<string>, string) => unit = "toMatch"
@send external toMatchRe: (expect<string>, Js.Re.t) => unit = "toMatch"
@send external toMatchObject: (expect<'a>, 'b) => unit = "toMatchObject"
// @send external toMatchSnapshot(propertyMatchers?, hint?)
// @send external toMatchInlineSnapshot(propertyMatchers?, inlineSnapshot)
// @send external toStrictEqual(value)
// @send external toThrow(error?)
// @send external toThrowErrorMatchingSnapshot(hint?)
// @send external toThrowErrorMatchingInlineSnapshot(inlineSnapshot)

@val external test: (string, (unit => unit) => unit) => unit = "test"
// not calling done seems to hang these tests? idk why -AxM
let test = (a, b) =>
  test(a, done => {
    b()
    done()
  })

let it = test

type done
@val external testDone: (string, done => unit) => unit = "test"

// These magical casts need to return a singular value (arity 1)
// So the return functions must be uncurried - AxM
external doneToSuccess: (done, . unit) => unit = "%identity"
external doneToFailure: (done, . 'error) => unit = "%identity"

//rescript seems to let return values bleed when weve cast it to unit and it bothers jest, so lets be sure? -AxM
let testDone = (str, fn) =>
  testDone(str, done => {
    // doneToSuccess has to return uncurried but we dont want to trouble callers with that rn so wrap it
    let success = done->doneToSuccess
    let success = () => success(.)

    // doneToFailure has to return uncurried but we dont want to trouble callers with that rn so wrap it
    let failure = done->doneToFailure
    let failure = err => failure(. err)

    fn(success, failure)
    ()
  })
let itDone = testDone

// external testPromise fails to complete for some reason, but we can implement in terms of testDone - AxM
// @val external testPromise: (string, () => Js.Promise.t<unit>) => unit = "test"
let testPromise = (str, fn) => {
  testDone(str, (success, failure) => {
    fn()->Promise.tapCatch(failure)->Promise.const()->Promise.tap(success)->Promise.void
    ()
  })
}

let itPromise = testPromise