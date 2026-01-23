///|
/// Corner case tests for nested transformations

///|
test "corner: deeply nested object modification" {
  debug_inspect(
    test_query(".a.b.c.d = 99", "{\"a\":{\"b\":{\"c\":{\"d\":1}}}}"),
    content="Number(99)",
  )
}

///|
test "corner: creating nested structure" {
  debug_inspect(test_query(".a.b.c = 42", "{}"), content="Number(42)")
}

///|
test "corner: array within object modification" {
  debug_inspect(
    test_query(
      ".items[1].value = 99", "{\"items\":[{\"value\":1},{\"value\":2}]}",
    ),
    content="Number(99)",
  )
}
