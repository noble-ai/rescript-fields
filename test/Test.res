// This takes uncurried functions because an Array map yielding thunks has some
// bug where it dereferences undefined idk.
let chain = (~delay, steps: array<(. unit) => ()>) => {
  Promise.sequence( steps, x => Promise.return(x(.))
  ->Promise.delay(~ms=delay))
  ->Promise.const()
}

