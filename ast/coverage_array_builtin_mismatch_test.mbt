///|
test "coverage: array builtins type mismatches" {
  assert_true((try? coverage_eval("sort", "1")) is Err(_))
  assert_true((try? coverage_eval("reverse", "1")) is Err(_))
  assert_true((try? coverage_eval("unique", "1")) is Err(_))
  assert_true((try? coverage_eval("min", "1")) is Err(_))
  assert_true((try? coverage_eval("max", "1")) is Err(_))
}
