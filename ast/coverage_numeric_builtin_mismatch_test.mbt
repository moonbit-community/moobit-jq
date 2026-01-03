///|
test "coverage: numeric builtins type mismatches" {
  assert_true((try? coverage_eval("floor", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("sqrt", "\"x\"")) is Err(_))
}

///|
test "coverage: add ignores non-numbers" {
  @json.inspect(coverage_eval("add", "[1, \"x\", 2]"), content=[3])
}
