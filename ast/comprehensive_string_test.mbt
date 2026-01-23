///|
/// Comprehensive string-focused tests

// ============================================================================
// String Interpolation Tests
// ============================================================================

///|
test "string interpolation: basic" {
  debug_inspect(
    test_query("\"Hello \\(.name)!\"", "{\"name\":\"Alice\"}"),
    content="String(\"Hello Alice!\")",
  )
}

///|
test "string interpolation: multiple expressions" {
  debug_inspect(
    test_query(
      "\"\\(.first) \\(.last)\"", "{\"first\":\"John\",\"last\":\"Doe\"}",
    ),
    content="String(\"John Doe\")",
  )
}

///|
test "string interpolation: nested access" {
  debug_inspect(
    test_query(
      "\"Name: \\(.user.name), Age: \\(.user.age)\"", "{\"user\":{\"name\":\"Bob\",\"age\":30}}",
    ),
    content=(
      #|String("Name: Bob, Age: Number(30)")
    ),
  )
}

///|
test "string interpolation: with expressions" {
  debug_inspect(
    test_query("\"Result: \\(. * 2)\"", "5"),
    content=(
      #|String("Result: Number(10)")
    ),
  )
}

///|
test "string interpolation: array access" {
  debug_inspect(
    test_query("\"First: \\(.[0]), Last: \\(.[-1])\"", "[1,2,3,4,5]"),
    content=(
      #|String("First: Number(1), Last: Number(5)")
    ),
  )
}

///|
test "string interpolation: complex expression" {
  debug_inspect(
    test_query(
      "\"Sum: \\(.a + .b), Product: \\(.a * .b)\"", "{\"a\":3,\"b\":7}",
    ),
    content=(
      #|String("Sum: Number(10), Product: Number(21)")
    ),
  )
}

// ============================================================================
// String Operations
// ============================================================================

///|
test "ltrimstr: remove prefix" {
  debug_inspect(
    test_query("ltrimstr(\"Hello \")", "\"Hello World\""),
    content="String(\"World\")",
  )
}

///|
test "rtrimstr: remove suffix" {
  debug_inspect(
    test_query("rtrimstr(\" World\")", "\"Hello World\""),
    content="String(\"Hello\")",
  )
}

///|
test "ascii_upcase: uppercase conversion" {
  debug_inspect(
    test_query("ascii_upcase", "\"hello world\""),
    content="String(\"HELLO WORLD\")",
  )
}

///|
test "ascii_downcase: lowercase conversion" {
  debug_inspect(
    test_query("ascii_downcase", "\"HELLO WORLD\""),
    content="String(\"hello world\")",
  )
}

///|
test "startswith: prefix check" {
  debug_inspect(
    test_query("startswith(\"Hello\")", "\"Hello World\""),
    content="True",
  )
}

///|
test "endswith: suffix check" {
  debug_inspect(
    test_query("endswith(\"World\")", "\"Hello World\""),
    content="True",
  )
}

///|
test "contains: substring check" {
  debug_inspect(
    test_query("contains(\"lo Wo\")", "\"Hello World\""),
    content="True",
  )
}

///|
test "split: split string" {
  debug_inspect(
    test_query("split(\",\")", "\"a,b,c\""),
    content="Array([String(\"a\"), String(\"b\"), String(\"c\")])",
  )
}

///|
test "join: join array elements" {
  debug_inspect(
    test_query("join(\"-\")", "[\"2024\",\"12\",\"13\"]"),
    content="String(\"2024-12-13\")",
  )
}

// ============================================================================
// Edge Cases
// ============================================================================

///|
test "edge: unicode string interpolation" {
  debug_inspect(
    test_query("\"Hello \\(.name) 👋\"", "{\"name\":\"世界\"}"),
    content="ParseError: UnterminatedString(0)",
  )
}
