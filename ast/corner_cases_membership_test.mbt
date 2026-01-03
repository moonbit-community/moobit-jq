///|
/// Corner case tests for array search and membership

///|
test "corner: indices finds all occurrences" {
  inspect(
    test_query("indices(2)", "[1,2,3,2,1]"),
    content="Array([Number(1), Number(3)])",
  )
}

///|
test "corner: indices with no matches" {
  inspect(test_query("indices(99)", "[1,2,3]"), content="Array([])")
}

///|
test "corner: inside checks array containment" {
  inspect(test_query("inside([1,2,3,4,5])", "[1,2]"), content="True")
}

///|
test "corner: inside with non-subset" {
  inspect(test_query("inside([1,2,3])", "[1,2,4]"), content="False")
}
