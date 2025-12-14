///|
fn cov_eval8(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  eval(expr, json_input).collect()
}

///|
test "coverage: iterator empty branch for .[]" {
  @json.inspect(cov_eval8(".[]", "1"), content=[])
}

///|
test "coverage: object construction edge cases" {
  @json.inspect(cov_eval8("{(empty): 1, \"a\": 2}", "null"), content=[
    { "a": 2 },
  ])
  assert_true((try? cov_eval8("{(1): 2}", "null")) is Err(_))
  @json.inspect(cov_eval8("{\"a\": empty}", "null"), content=[{ "a": null }])
  @json.inspect(cov_eval8("{a}", "1"), content=[{ "a": null }])
}

///|
test "coverage: length/keys/values coverage and mismatches" {
  @json.inspect(cov_eval8("length", "{\"a\": 1, \"b\": 2}"), content=[2])
  @json.inspect(cov_eval8("length", "null"), content=[0])
  assert_true((try? cov_eval8("length", "true")) is Err(_))
  @json.inspect(cov_eval8("values", "{\"a\": 1, \"b\": 2}"), content=[[1, 2]])
  assert_true((try? cov_eval8("values", "true")) is Err(_))
  assert_true((try? cov_eval8("keys", "true")) is Err(_))
}

///|
test "coverage: array builtins type mismatches" {
  assert_true((try? cov_eval8("sort", "1")) is Err(_))
  assert_true((try? cov_eval8("reverse", "1")) is Err(_))
  assert_true((try? cov_eval8("unique", "1")) is Err(_))
  assert_true((try? cov_eval8("min", "1")) is Err(_))
  assert_true((try? cov_eval8("max", "1")) is Err(_))
}

///|
test "coverage: numeric builtins type mismatches" {
  assert_true((try? cov_eval8("floor", "\"x\"")) is Err(_))
  assert_true((try? cov_eval8("sqrt", "\"x\"")) is Err(_))
}

///|
test "coverage: add ignores non-numbers" {
  @json.inspect(cov_eval8("add", "[1, \"x\", 2]"), content=[3])
}
