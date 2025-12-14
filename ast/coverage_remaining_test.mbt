///|
fn cov_eval5(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  eval(expr, json_input).collect()
}

///|
test "coverage: repeat with limit and empty inner" {
  @json.inspect(cov_eval5("limit(5; repeat(1))", "null"), content=[
    1, 1, 1, 1, 1,
  ])
  @json.inspect(cov_eval5("limit(5; repeat(empty))", "null"), content=[])
}

///|
test "coverage: explode/implode and type mismatches" {
  @json.inspect(cov_eval5("explode", "\"A\""), content=[[65]])
  @json.inspect(cov_eval5("implode", "[65]"), content=["A"])
  // Invalid code point is ignored.
  @json.inspect(cov_eval5("implode", "[1114112]"), content=[""])
  assert_true((try? cov_eval5("explode", "1")) is Err(_))
  assert_true((try? cov_eval5("implode", "\"x\"")) is Err(_))
}

///|
test "coverage: fromjson parses and errors" {
  @json.inspect(cov_eval5("fromjson", "\"{\\\"a\\\": 1}\""), content=[
    { "a": 1 },
  ])
  assert_true((try? cov_eval5("fromjson", "\"{\"")) is Err(_))
  assert_true((try? cov_eval5("fromjson", "1")) is Err(_))
}

///|
test "coverage: min_by/max_by empty and invalid key" {
  @json.inspect(cov_eval5("min_by(.)", "[]"), content=[null])
  @json.inspect(cov_eval5("max_by(.)", "[]"), content=[null])
  // Key expression yields empty => null.
  @json.inspect(cov_eval5("min_by(empty)", "[1, 2]"), content=[null])
  @json.inspect(cov_eval5("max_by(empty)", "[1, 2]"), content=[null])
  assert_true((try? cov_eval5("min_by(.)", "1")) is Err(_))
  assert_true((try? cov_eval5("max_by(.)", "1")) is Err(_))
}

///|
test "coverage: combinations empty and type mismatch" {
  @json.inspect(cov_eval5("combinations", "[]"), content=[])
  assert_true((try? cov_eval5("combinations", "1")) is Err(_))
}

///|
test "coverage: array comparisons exercise element and length ordering" {
  @json.inspect(cov_eval5("[1] < [1, 2]", "null"), content=[true])
  @json.inspect(cov_eval5("[1, 0] < [1, 2]", "null"), content=[true])
}

///|
test "coverage: invalid arithmetic operations error" {
  assert_true((try? cov_eval5("1 + []", "null")) is Err(_))
  assert_true((try? cov_eval5("1 - \"x\"", "null")) is Err(_))
  assert_true((try? cov_eval5("1 * {}", "null")) is Err(_))
  assert_true((try? cov_eval5("1 / []", "null")) is Err(_))
}

///|
test "coverage: setpath out-of-range keeps original" {
  @json.inspect(cov_eval5("setpath([10]; 1)", "[0]"), content=[[0]])
}
