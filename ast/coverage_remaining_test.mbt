///|
test "coverage: repeat with limit and empty inner" {
  @json.inspect(coverage_eval("limit(5; repeat(1))", "null"), content=[
    1, 1, 1, 1, 1,
  ])
  @json.inspect(coverage_eval("limit(5; repeat(empty))", "null"), content=[])
}

///|
test "coverage: explode/implode and type mismatches" {
  @json.inspect(coverage_eval("explode", "\"A\""), content=[[65]])
  @json.inspect(coverage_eval("implode", "[65]"), content=["A"])
  // Invalid code point is ignored.
  @json.inspect(coverage_eval("implode", "[1114112]"), content=[""])
  assert_true((try? coverage_eval("explode", "1")) is Err(_))
  assert_true((try? coverage_eval("implode", "\"x\"")) is Err(_))
}

///|
test "coverage: fromjson parses and errors" {
  @json.inspect(coverage_eval("fromjson", "\"{\\\"a\\\": 1}\""), content=[
    { "a": 1 },
  ])
  assert_true((try? coverage_eval("fromjson", "\"{\"")) is Err(_))
  assert_true((try? coverage_eval("fromjson", "1")) is Err(_))
}

///|
test "coverage: min_by/max_by empty and invalid key" {
  @json.inspect(coverage_eval("min_by(.)", "[]"), content=[null])
  @json.inspect(coverage_eval("max_by(.)", "[]"), content=[null])
  // Key expression yields empty => null.
  @json.inspect(coverage_eval("min_by(empty)", "[1, 2]"), content=[null])
  @json.inspect(coverage_eval("max_by(empty)", "[1, 2]"), content=[null])
  assert_true((try? coverage_eval("min_by(.)", "1")) is Err(_))
  assert_true((try? coverage_eval("max_by(.)", "1")) is Err(_))
}

///|
test "coverage: combinations empty and type mismatch" {
  @json.inspect(coverage_eval("combinations", "[]"), content=[])
  assert_true((try? coverage_eval("combinations", "1")) is Err(_))
}

///|
test "coverage: array comparisons exercise element and length ordering" {
  @json.inspect(coverage_eval("[1] < [1, 2]", "null"), content=[true])
  @json.inspect(coverage_eval("[1, 0] < [1, 2]", "null"), content=[true])
}

///|
test "coverage: invalid arithmetic operations error" {
  assert_true((try? coverage_eval("1 + []", "null")) is Err(_))
  assert_true((try? coverage_eval("1 - \"x\"", "null")) is Err(_))
  assert_true((try? coverage_eval("1 * {}", "null")) is Err(_))
  assert_true((try? coverage_eval("1 / []", "null")) is Err(_))
}

///|
test "coverage: setpath out-of-range keeps original" {
  @json.inspect(coverage_eval("setpath([10]; 1)", "[0]"), content=[[0]])
}
