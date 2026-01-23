///|
/// Corner case tests for recursive functions

///|
test "corner: recursive function with base case" {
  debug_inspect(
    test_query(
      "def sum: if length == 0 then 0 else .[0] + (.[1:] | sum) end; sum", "[1,2,3,4,5]",
    ),
    content="Number(15)",
  )
}

///|
test "corner: mutually recursive functions" {
  debug_inspect(
    test_query(
      "def even: if . == 0 then true elif . == 1 then false else (. - 2) | even end; def odd: if . == 0 then false elif . == 1 then true else (. - 2) | odd end; even",
      "6",
    ),
    content=(
      #|ParseError: UnexpectedToken("TElif", "TElse")
    ),
  )
}
