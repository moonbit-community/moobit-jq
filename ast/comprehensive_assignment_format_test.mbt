///|
/// Comprehensive tests for assignment operators and format functions

// ============================================================================
// Compound Assignment Operator Tests
// ============================================================================

///|
test "compound assignment: += with number" {
  debug_inspect(
    test_query(".x += 5", "{\"x\":10}"),
    content=(
      #|Object({"x": Number(15)})
    ),
  )
}

///|
test "compound assignment: -= with number" {
  debug_inspect(
    test_query(".x -= 3", "{\"x\":10}"),
    content=(
      #|Object({"x": Number(7)})
    ),
  )
}

///|
test "compound assignment: *= with number" {
  debug_inspect(
    test_query(".x *= 3", "{\"x\":4}"),
    content=(
      #|Object({"x": Number(12)})
    ),
  )
}

///|
test "compound assignment: /= with number" {
  debug_inspect(
    test_query(".x /= 2", "{\"x\":20}"),
    content=(
      #|Object({"x": Number(10)})
    ),
  )
}

///|
test "compound assignment: %= modulo" {
  debug_inspect(
    test_query(".x %= 3", "{\"x\":10}"),
    content=(
      #|Object({"x": Number(1)})
    ),
  )
}

///|
test "compound assignment: //= alternative" {
  debug_inspect(
    test_query(".x //= 42", "{\"y\":10}"),
    content=(
      #|Object({"y": Number(10), "x": Number(42)})
    ),
  )
}

///|
test "compound assignment: += with array concat" {
  debug_inspect(
    test_query(".items += [4,5]", "{\"items\":[1,2,3]}"),
    content=(
      #|Object({"items": Array([Number(1), Number(2), Number(3), Number(4), Number(5)])})
    ),
  )
}

///|
test "compound assignment: += with string concat" {
  debug_inspect(
    test_query(".msg += \" World\"", "{\"msg\":\"Hello\"}"),
    content=(
      #|Object({"msg": String("Hello World")})
    ),
  )
}

// ============================================================================
// Format Function Tests
// ============================================================================

///|
test "format: @base64 encoding" {
  debug_inspect(
    test_query("@base64", "\"Hello\""),
    content="String(\"SGVsbG8=\")",
  )
}

///|
test "format: @base64d decoding" {
  debug_inspect(
    test_query("@base64d", "\"SGVsbG8=\""),
    content="String(\"Hello\")",
  )
}

///|
test "format: @uri encoding" {
  debug_inspect(
    test_query("@uri", "\"hello world\""),
    content="String(\"hello%20world\")",
  )
}

///|
test "format: @html escaping" {
  debug_inspect(
    test_query("@html", "\"<div>Test</div>\""),
    content="String(\"&lt;div&gt;Test&lt;/div&gt;\")",
  )
}

///|
test "format: @csv simple array" {
  debug_inspect(
    test_query("@csv", "[\"a\",\"b\",\"c\"]"),
    content="String(\"a,b,c\")",
  )
}

///|
test "format: @csv with quotes" {
  debug_inspect(
    test_query("@csv", "[\"hello, world\",\"test\"]"),
    content="String(\"\\\"hello, world\\\",test\")",
  )
}

///|
test "format: @tsv tab separated" {
  debug_inspect(
    test_query("@tsv", "[\"a\",\"b\",\"c\"]"),
    content="String(\"a\\tb\\tc\")",
  )
}

///|
test "format: @json stringify" {
  debug_inspect(
    test_query("@json", "{\"x\":1,\"y\":2}"),
    content="String(\"Object({\\\"x\\\": Number(1), \\\"y\\\": Number(2)})\")",
  )
}

///|
test "format: @text" {
  debug_inspect(
    test_query("@text", "{\"x\":42}"),
    content="String(\"Object({\\\"x\\\": Number(42)})\")",
  )
}
