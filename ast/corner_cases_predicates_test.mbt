///|
/// Corner case tests for any/all predicates

///|
test "corner: any with mixed booleans" {
  debug_inspect(test_query("any", "[true,false,true]"), content="True")
}

///|
test "corner: any with all false" {
  debug_inspect(test_query("any", "[false,false,false]"), content="False")
}

///|
test "corner: all with all true" {
  debug_inspect(test_query("all", "[true,true,true]"), content="True")
}

///|
test "corner: all with one false" {
  debug_inspect(test_query("all", "[true,false,true]"), content="False")
}

///|
test "corner: any with empty array" {
  debug_inspect(test_query("any", "[]"), content="False")
}

///|
test "corner: all with empty array" {
  debug_inspect(test_query("all", "[]"), content="True")
}

///|
test "corner: any with generator and condition" {
  debug_inspect(test_query("any(1,2,3,4; . > 3)", "null"), content="True")
}

///|
test "corner: all with generator and condition" {
  debug_inspect(test_query("all(1,2,3,4; . > 0)", "null"), content="True")
}
