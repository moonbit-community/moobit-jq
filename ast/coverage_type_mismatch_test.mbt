///|
test "coverage: iterator empty branch for .[]" {
  @json.inspect(coverage_eval(".[]", "1"), content=[])
}

///|
test "coverage: object construction edge cases" {
  @json.inspect(coverage_eval("{(empty): 1, \"a\": 2}", "null"), content=[
    { "a": 2 },
  ])
  assert_true((try? coverage_eval("{(1): 2}", "null")) is Err(_))
  @json.inspect(coverage_eval("{\"a\": empty}", "null"), content=[{ "a": null }])
  @json.inspect(coverage_eval("{a}", "1"), content=[{ "a": null }])
}

///|
test "coverage: length/keys/values coverage and mismatches" {
  @json.inspect(coverage_eval("length", "{\"a\": 1, \"b\": 2}"), content=[2])
  @json.inspect(coverage_eval("length", "null"), content=[0])
  assert_true((try? coverage_eval("length", "true")) is Err(_))
  @json.inspect(coverage_eval("values", "{\"a\": 1, \"b\": 2}"), content=[[1, 2]])
  assert_true((try? coverage_eval("values", "true")) is Err(_))
  assert_true((try? coverage_eval("keys", "true")) is Err(_))
}

///|
test "coverage: array builtins type mismatches" {
  assert_true((try? coverage_eval("sort", "1")) is Err(_))
  assert_true((try? coverage_eval("reverse", "1")) is Err(_))
  assert_true((try? coverage_eval("unique", "1")) is Err(_))
  assert_true((try? coverage_eval("min", "1")) is Err(_))
  assert_true((try? coverage_eval("max", "1")) is Err(_))
}

///|
test "coverage: numeric builtins type mismatches" {
  assert_true((try? coverage_eval("floor", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("sqrt", "\"x\"")) is Err(_))
}

///|
test "coverage: add ignores non-numbers" {
  @json.inspect(coverage_eval("add", "[1, \"x\", 2]"), content=[3])
}
