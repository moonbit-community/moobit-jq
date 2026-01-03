///|
/// Corner case tests for range and iteration

///|
test "corner: range with single argument" {
  inspect(
    test_query("[range(5)]", "null"),
    content="Array([Number(0), Number(1), Number(2), Number(3), Number(4)])",
  )
}

///|
test "corner: range with start and end" {
  inspect(
    test_query("[range(2;5)]", "null"),
    content="Array([Number(2), Number(3), Number(4)])",
  )
}

///|
test "corner: range with step" {
  inspect(
    test_query("[range(0;10;2)]", "null"),
    content="Array([Number(0), Number(2), Number(4), Number(6), Number(8)])",
  )
}

///|
test "corner: range with negative step" {
  inspect(
    test_query("[range(10;0;-2)]", "null"),
    content="Array([Number(10), Number(8), Number(6), Number(4), Number(2)])",
  )
}

///|
test "corner: range with zero count" {
  inspect(test_query("[range(0)]", "null"), content="Array([])")
}

///|
test "corner: first from multiple values" {
  inspect(test_query("first(1,2,3,4,5)", "null"), content="Number(1)")
}

///|
test "corner: last from multiple values" {
  inspect(test_query("last(1,2,3,4,5)", "null"), content="Number(5)")
}

///|
test "corner: first from array elements" {
  inspect(test_query("first(.[])", "[10,20,30]"), content="Number(10)")
}

///|
test "corner: last from array elements" {
  inspect(test_query("last(.[])", "[10,20,30]"), content="Number(30)")
}

///|
test "corner: first with empty" {
  inspect(test_query("first(empty)", "null"), content="")
}

///|
test "corner: repeat generates infinite stream (limited)" {
  inspect(
    test_query("limit(3; repeat(\"x\"))", "null"),
    content="String(\"x\"), String(\"x\"), String(\"x\")",
  )
}

///|
test "corner: repeat with expression" {
  inspect(
    test_query("limit(4; . | repeat(. * 2))", "1"),
    content="Number(2), Number(2), Number(2), Number(2)",
  )
}

///|
test "corner: until increments until condition" {
  inspect(test_query("until(. > 5; . + 1)", "1"), content="Number(6)")
}

///|
test "corner: until with already satisfied condition" {
  inspect(test_query("until(. > 5; . + 1)", "10"), content="Number(10)")
}

///|
test "corner: until with decrement" {
  inspect(test_query("until(. < 0; . - 1)", "5"), content="Number(-1)")
}
