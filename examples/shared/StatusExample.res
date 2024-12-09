@react.component
let make = (~title=?, ~enum: Store.enum, ~error) => {
  <div className=`status ${enum->Store.enumToA}`>
    { title->Option.map(x => `${x}: `->React.string)->Option.or(React.null) }
    {`${error->Option.or(enum->Store.enumToPretty)}`->React.string}
  </div>
}

