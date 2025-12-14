///|
/// Helper to collect and inspect results
fn test_eval(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input)
  eval(expr, json_input).collect()
}

///|
/// Test identity
test "eval identity" {
  let results = test_eval(".", "42")
  @json.inspect(results, content=[42])
}

///|
test "eval identity with object" {
  let results = test_eval(".", "{\"a\": 1}")
  @json.inspect(results, content=[{ "a": 1 }])
}

///|
/// Test literals
test "eval null literal" {
  let results = test_eval("null", "42")
  @json.inspect(results, content=[null])
}

///|
test "eval number literal" {
  let results = test_eval("123", "{}")
  @json.inspect(results, content=[123])
}

///|
test "eval string literal" {
  let results = test_eval("\"hello\"", "null")
  @json.inspect(results, content=["hello"])
}

///|
/// Test field access
test "eval field access" {
  let results = test_eval(".name", "{\"name\": \"Alice\", \"age\": 30}")
  @json.inspect(results, content=["Alice"])
}

///|
test "eval missing field" {
  let results = test_eval(".missing", "{\"name\": \"Alice\"}")
  @json.inspect(results, content=[null])
}

///|
/// Test array operations
test "eval array index" {
  let results = test_eval(".[1]", "[10, 20, 30]")
  @json.inspect(results, content=[20])
}

///|
test "eval negative array index" {
  let results = test_eval(".[-1]", "[10, 20, 30]")
  @json.inspect(results, content=[30])
}

///|
test "eval array iterator" {
  let results = test_eval(".[]", "[1, 2, 3]")
  @json.inspect(results, content=[1, 2, 3])
}

///|
/// Test pipe operator
test "eval pipe" {
  let results = test_eval(".numbers | .[0]", "{\"numbers\": [1, 2, 3]}")
  @json.inspect(results, content=[1])
}

///|
/// Test comma operator
test "eval comma produces multiple results" {
  let results = test_eval(".a, .b", "{\"a\": 1, \"b\": 2}")
  @json.inspect(results, content=[1, 2])
}

///|
test "eval comma with literals" {
  let results = test_eval("1, 2, 3", "null")
  @json.inspect(results, content=[1, 2, 3])
}

///|
/// Test arithmetic operators
test "eval addition" {
  let results = test_eval(".a + .b", "{\"a\": 10, \"b\": 5}")
  @json.inspect(results, content=[15])
}

///|
test "eval string concatenation" {
  let results = test_eval(
    ".first + .last", "{\"first\": \"Hello\", \"last\": \" World\"}",
  )
  @json.inspect(results, content=["Hello World"])
}

///|
test "eval subtraction" {
  let results = test_eval(".a - .b", "{\"a\": 10, \"b\": 3}")
  @json.inspect(results, content=[7])
}

///|
test "eval multiplication" {
  let results = test_eval(".a * .b", "{\"a\": 6, \"b\": 7}")
  @json.inspect(results, content=[42])
}

///|
test "eval division" {
  let results = test_eval(".a / .b", "{\"a\": 20, \"b\": 4}")
  @json.inspect(results, content=[5])
}

///|
/// Test comparison operators
test "eval equality" {
  let results = test_eval(".a == .b", "{\"a\": 5, \"b\": 5}")
  @json.inspect(results, content=[true])
}

///|
test "eval inequality" {
  let results = test_eval(".a != .b", "{\"a\": 5, \"b\": 3}")
  @json.inspect(results, content=[true])
}

///|
test "eval less than" {
  let results = test_eval(".a < .b", "{\"a\": 3, \"b\": 5}")
  @json.inspect(results, content=[true])
}

///|
/// Test built-in functions
test "eval length on array" {
  let results = test_eval("length", "[1, 2, 3, 4, 5]")
  @json.inspect(results, content=[5])
}

///|
test "eval length on string" {
  let results = test_eval("length", "\"hello\"")
  @json.inspect(results, content=[5])
}

///|
test "eval type" {
  @json.inspect(test_eval("type", "42"), content=["number"])
  @json.inspect(test_eval("type", "\"hello\""), content=["string"])
  @json.inspect(test_eval("type", "null"), content=["null"])
}

///|
test "eval not" {
  let results = test_eval("not", "false")
  @json.inspect(results, content=[true])
}
